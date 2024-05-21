#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import asyncio
import cffi
import functools
import os
import numpy as np
from pynq.buffer import PynqBuffer
from pynq.ps import CPU_ARCH, ZU_ARCH
from .constants import LIB_SEARCH_PATH
from .common import VideoMode


def _fourcc_int(fourcc):
    if len(fourcc) != 4:
        raise ValueError("FourCC code must be four characters")
    return (ord(fourcc[0]) |
            (ord(fourcc[1]) << 8) |
            (ord(fourcc[2]) << 16) |
            (ord(fourcc[3]) << 24))


class DrmDriver:
    """Driver for DRM-based output through the Linux kernel

    This driver provides a zero-copy interface to the DRM subsystem
    exposing a similar API to the HDMI interface.
    The API should be configured with a PixelFormat containing a FourCC
    which will be passed to the Linux video subsystem.

    Once configured frames can be retrieved using `newframe` which returns
    a numpy array mapped to a frame buffer. The frame can be switched using
    `writeframe`. Once a frame has been written it should not be modified as
    ownership has been transferred to the kernel.

    """

    _videolib = None
    _ffi = None

    def __init__(self, device_path, event_loop=None):
        """Create a new driver instance

        Parameters
        ----------
        device_path : str
            The device to open
        event_loop : asyncio.AbstractEventLoop
            The event loop to use if the default is not wanted

        """
        if self._videolib is None:
            self._openlib()

        self._video_fd = os.open(device_path, os.O_RDWR)
        self._video_file = os.fdopen(self._video_fd, "r+b", buffering=0)

        self._device = self._videolib.pynqvideo_device_init(self._video_fd)
        if self._device == 0:
            raise RuntimeError("Unable to create DRM device")

        if event_loop:
            self._loop = event_loop
        else:
            self._loop = asyncio.get_event_loop()
        self._loop.add_reader(self._video_file,
                              functools.partial(DisplayPort._callback, self))
        self._pageflip_event = asyncio.Event()
        self.mode = None
        mode_count = self._videolib.pynqvideo_num_modes(self._device)
        raw_modes = self._ffi.new('struct video_mode[{}]'.format(mode_count))
        self._videolib.pynqvideo_get_modes(self._device, raw_modes, mode_count)
        self.modes = [VideoMode(m.width, m.height, 24, m.refresh)
                      for m in raw_modes]

    def _openlib(self):
        self._ffi = cffi.FFI()
        self._ffi.cdef("""
        struct video_mode {
            int width;
            int height;
            int refresh;
        };
        void* pynqvideo_device_init(int fd);
        int pynqvideo_device_set_mode(void* device, int width, int height,
                        int refreh, int colorspace);
        void pynqvideo_device_close(void* device);
        void pynqvideo_device_handle_events(void* device);

        void* pynqvideo_frame_new(void* device);
        int pynqvideo_frame_write(void* device, void* frame);
        uint64_t pynqvideo_frame_physaddr(void* frame);
        void* pynqvideo_frame_data(void* frame);
        uint64_t pynqvideo_frame_size(void* frame);
        uint32_t pynqvideo_frame_stride(void* frame);
        void pynqvideo_frame_free(void* device, void* frame);
        int pynqvideo_num_modes(void* device);
        int pynqvideo_get_modes(void* device, struct video_mode* modes, int length);
        """
                       )
        self._videolib = self._ffi.dlopen(os.path.join(LIB_SEARCH_PATH,
                                                       "libdisplayport.so"))

    def _callback(self):
        self._videolib.pynqvideo_device_handle_events(self._device)
        self._pageflip_event.set()

    def __del__(self):
        self.close()

    def configure(self, mode, pixelformat):
        """Configure the display output

        Raises an exception if the initialisation fails.

        Parameters
        ----------
        mode : VideoMode
            The resolution to set the output display to
        pixelformat : PixelFormat
            The pixel format to use - must contain a fourcc

        """
        if mode not in self.modes:
            raise ValueError("mode: {} is not supported".format(mode))
        if not pixelformat.fourcc:
            raise ValueError("pixelformat does not define a FourCC")
        ret = self._videolib.pynqvideo_device_set_mode(
            self._device, mode.width, mode.height, mode.fps,
            _fourcc_int(pixelformat.fourcc))
        if ret:
            raise RuntimeError("Monitor is not detected")
        self.mode = mode

    def start(self):
        """Dummy function to match the HDMI interface

        """
        pass

    def stop(self):
        """Dummy function to match the HDMI interface

        """
        pass

    def close(self):
        """Close the display device

        """
        if self._device:
            self._loop.remove_reader(self._video_file)
            self._videolib.pynqvideo_device_close(self._device)
            self._device = None
            self._video_file.close()

    def newframe(self):
        """Return a new frame which can later be written

        Frames are not zeroed before being returned so the calling
        application should make sure the frame is fully written.

        Returns
        -------
        pynq.PynqBuffer : numpy.ndarray mapped to a hardware frame

        """
        frame_pointer = self._videolib.pynqvideo_frame_new(self._device)
        data_pointer = self._videolib.pynqvideo_frame_data(frame_pointer)
        data_size = self._videolib.pynqvideo_frame_size(frame_pointer)
        data_physaddr = self._videolib.pynqvideo_frame_physaddr(frame_pointer)
        data_stride = self._videolib.pynqvideo_frame_stride(frame_pointer)
        if len(self.mode.shape) == 2:
            expected_stride = self.mode.shape[1]
        else:
            expected_stride = self.mode.shape[1] * self.mode.shape[2]
        buffer = self._ffi.buffer(data_pointer, data_size)
        if expected_stride == data_stride:
            array = np.frombuffer(buffer, dtype='u1').reshape(self.mode.shape)
        else:
            raw_array = np.frombuffer(buffer, dtype='u1').reshape(
                    [self.mode.shape[0], data_stride])
            array = raw_array[:,0:expected_stride].reshape(self.mode.shape)
        view = array.view(PynqBuffer)
        view.pointer = frame_pointer
        view.device_address = data_physaddr
        view.return_to = self
        return view

    def return_pointer(self, pointer):
        if pointer:
            self._videolib.pynqvideo_frame_free(self._device, pointer)

    def writeframe(self, frame):
        """Write a frame to the display.

        Raises an exception if the operation fails and blocks until a
        page-flip if there is already a frame scheduled to be displayed.

        Parameters
        ----------
        frame : pynq.ContiguousArray
            Frame to write - must have been created by `newframe`

        """
        ret = self._videolib.pynqvideo_frame_write(
            self._device, frame.pointer)
        if ret == -1:
            self._loop.run_until_complete(
                asyncio.ensure_future(self.writeframe_async(frame)))
        elif ret > 0:
            raise OSError(ret, "Can't write frame")
        else:
            self._videolib.pynqvideo_device_handle_events(self._device)
            # Frame should no longer be disposed
            frame.pointer = None

    async def writeframe_async(self, frame):
        """Write a frame to the display.

        Raises an exception if the operation fails and yields until a
        page-flip if there is already a frame scheduled to be displayed.

        Parameters
        ----------
        frame : pynq.ContiguousArray
            Frame to write - must have been created by `newframe`

        """
        ret = -1
        while ret != 0:
            ret = self._videolib.pynqvideo_frame_write(
                self._device, frame.pointer)
            if ret == 0:
                await asyncio.sleep(0)
                frame.disposed = True
            elif ret > 0:
                raise OSError(ret, "Can't write frame")
            else:
                self._pageflip_event.clear()
                await self._pageflip_event.wait()


if CPU_ARCH == ZU_ARCH:
    class DisplayPort(DrmDriver):
        """Subclass of DrmDriver which interacts with the
        hardened DisplayPort port on Zynq Ultrascale+ devices

        """

        def __init__(self, event_loop=None):
            """Create a new driver instance bound to card0 which
            should always be the hardened DisplayPort

            Parameters
            ----------
            event_loop : asyncio.AbstractEventLoop
                The event loop to use if the default is not wanted

            """
            super().__init__('/dev/dri/card0', event_loop)


