#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import asyncio
import contextlib
import functools
import numpy as np
import time
import warnings

from pynq import DefaultIP
from pynq import DefaultHierarchy
from pynq import Xlnk
from pynq.ps import CPU_ARCH_IS_SUPPORTED, CPU_ARCH

if CPU_ARCH_IS_SUPPORTED:
    import pynq.lib._video
else:
    warnings.warn("Pynq does not support the CPU Architecture: {}"
                  .format(CPU_ARCH), ResourceWarning)       

__author__ = "Giuseppe Natale, Yun Rock Qu, Peter Ogden"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class VideoMode:
    """Class for holding the information about a video mode

    Attributes
    ----------
    height : int
        Height of the video frame in lines
    width : int
        Width of the video frame in pixels
    stride : int
        Width of a line in the video frame in bytes
    bits_per_pixel : int
        Bits per pixel
    bytes_per_Pixel : int
        Bytes required to represent each pixel
    shape : tuple of int
        Numpy-style tuple describing the video frame

    """

    def __init__(self, width, height, bits_per_pixel, stride=None):
        self.width = width
        self.height = height
        self.bits_per_pixel = bits_per_pixel
        self.bytes_per_pixel = ((bits_per_pixel - 1) // 8) + 1
        if stride:
            self.stride = stride
        else:
            self.stride = width * self.bytes_per_pixel
        if self.bytes_per_pixel == 1:
            self.shape = (self.height, self.width)
        else:
            self.shape = (self.height, self.width, self.bytes_per_pixel)

    def __repr__(self):
        return ("VideoMode: width={} height={} bpp={}"
                .format(self.width, self.height, self.bits_per_pixel))


class HDMIInFrontend(DefaultHierarchy):
    """Class for interacting the with HDMI input frontend

    This class is used for enabling the HDMI input and retrieving
    the mode of the incoming video

    Attributes
    ----------
    mode : VideoMode
        The detected mode of the incoming video stream

    """

    def __init__(self, description):
        super().__init__(description)

    def start(self, init_timeout=10):
        """Method that blocks until the video mode is
        successfully detected

        """
        ip_dict = self.description
        gpio_description = ip_dict['ip']['axi_gpio_hdmiin']
        gpio_dict = {
            'BASEADDR': gpio_description['phys_addr'],
            'INTERRUPT_PRESENT': 1,
            'IS_DUAL': 1,
        }
        vtc_description = ip_dict['ip']['vtc_in']
        vtc_capture_addr = vtc_description['phys_addr']
        self._capture = pynq.lib._video._capture(gpio_dict,
                                                 vtc_capture_addr,
                                                 init_timeout)

        while self.mode.height == 0:
            pass
        # First mode detected is garbage so wait a while for
        # it to stabilise
        time.sleep(1)

    def stop(self):
        """Currently empty function included for symmetry with
        the HDMIOutFrontend class

        """
        pass

    @staticmethod
    def checkhierarchy(description):
        return ('vtc_in' in description['ip'] and
                'axi_gpio_hdmiin' in description['ip'])

    @property
    def mode(self):
        return VideoMode(self._capture.frame_width(),
                         self._capture.frame_height(), 24)


_outputmodes = {
    (640, 480): 0,
    (800, 600): 1,
    (1280, 720): 2,
    (1280, 1024): 3,
    (1920, 1080): 4
}


class HDMIOutFrontend(DefaultHierarchy):
    """Class for interacting the HDMI output frontend

    This class is used for enabling the HDMI output and setting
    the desired mode of the video stream

    Attributes
    ----------
    mode : VideoMode
        Desired mode for the output video. Must be set prior
        to calling start

    """

    @staticmethod
    def checkhierarchy(description):
        return ('vtc_out' in description['ip'] and
                'axi_dynclk' in description['ip'])

    def __init__(self, description):
        """Create the HDMI output front end

        Parameters
        ----------
        vtc_description : dict
            The IP dictionary entry for the video timing controller to use
        clock_description : dict
            The IP dictionary entry for the clock generator to use

        """
        super().__init__(description)
        ip_dict = self.description['ip']
        vtc_description = ip_dict['vtc_out']
        clock_description = ip_dict['axi_dynclk']
        vtc_capture_addr = vtc_description['phys_addr']
        clock_addr = clock_description['phys_addr']
        self._display = pynq.lib._video._display(vtc_capture_addr,
                                                 clock_addr, 1)
        self.start = self._display.start
        """Start the HDMI output - requires the that mode is already set"""

        self.stop = self._display.stop
        """Stop the HDMI output"""

    @property
    def mode(self):
        """Get or set the video mode for the HDMI output, must be set to one
        of the following resolutions:

        640x480
        800x600
        1280x720
        1280x1024
        1920x1080

        Any other resolution  will result in a ValueError being raised.
        The bits per pixel will always be 24 when retrieved and ignored
        when set.

        """
        return VideoMode(self._display.frame_width(),
                         self._display.frame_height(), 24)

    @mode.setter
    def mode(self, value):
        resolution = (value.width, value.height)
        if resolution in _outputmodes:
            self._display.mode(_outputmodes[resolution])
        else:
            raise ValueError("Invalid Output resolution {}x{}"
                             .format(value.width, value.height))


class _FrameCache:
    _xlnk = None

    def __init__(self, mode, capacity=5):
        self._cache = []
        self._mode = mode
        self._capacity = capacity

    def getframe(self):
        """Retrieve a frame from the cache or create a new frame if the
        cache is empty. The freebuffer method of the returned array is
        overriden to return the object to the cache rather than freeing
        the object.

        """
        if self._cache:
            frame = self._cache.pop()
        else:
            if _FrameCache._xlnk is None:
                _FrameCache._xlnk = Xlnk()
            frame = _FrameCache._xlnk.cma_array(
                shape=self._mode.shape, dtype=np.uint8)
        frame.original_freebuffer = frame.freebuffer
        frame.freebuffer = functools.partial(
            _FrameCache.returnframe, self, frame)
        return frame

    def returnframe(self, frame):
        frame.freebuffer = frame.original_freebuffer
        if len(self._cache) >= self._capacity:
            frame.freebuffer()
        else:
            self._cache.append(frame)

    def clear(self):
        for frame in self._cache:
            frame.freebuffer()
        self._cache.clear()


class AxiVDMA(DefaultIP):
    """Driver class for the Xilinx VideoDMA IP core

    The driver is split into input and output channels are exposed using the
    readchannel and writechannel attributes. Each channel has start and
    stop methods to control the data transfer. All channels MUST be stopped
    before reprogramming the bitstream or inconsistent behaviour may result.

    The DMA uses a single ownership model of frames in that frames are either
    owned by the DMA or the user code but not both. S2MMChannel.readframe
    and MM2SChannel.newframe both return a frame to the user. It is the
    user's responsibility to either free the frame using the freebuffer()
    method or to hand ownership back to the DMA using MM2SChannel.writeframe.
    Once ownership has been returned the user should not access the contents
    of the frame as the underlying memory may be deleted without warning.

    Attributes
    ----------
    readchannel : AxiVDMA.S2MMChannel
        Video input DMA channel
    writechannel : AxiVDMA.MM2SChannel
        Video output DMA channel

    """
    class _FrameList:
        """Internal helper class for handling the list of frames associated
        with a DMA channel. Assumes ownership of all frames it contains
        unless explicitly removed with takeownership

        """

        def __init__(self, parent, offset, count):
            self._frames = [None] * count
            self._mmio = parent._mmio
            self._offset = offset
            self._slaves = set()
            self.count = count
            self.reload = parent.reload

        def __getitem__(self, index):
            frame = self._frames[index]
            return frame

        def takeownership(self, index):
            self._frames[index] = None

        def __len__(self):
            return self.count

        def __setitem__(self, index, frame):
            if self._frames[index] is not None:
                self._frames[index].freebuffer()
            self._frames[index] = frame
            if frame is not None:
                self._mmio.write(self._offset + 4 * index,
                                 frame.physical_address)
            else:
                self._mmio.write(self._offset + 4 * index, 0)
            self.reload()
            for s in self._slaves:
                s[index] = frame
                s.takeownership(index)

        def addslave(self, slave):
            self._slaves.add(slave)
            for i in range(len(self._frames)):
                slave[i] = self[i]
                slave.takeownership(i)
            slave.reload()

        def removeslave(self, slave):
            self._slaves.remove(slave)

    class S2MMChannel:
        """Read channel of the Video DMA

        Brings frames from the video input into memory. Hands ownership of
        the read frames to the user code.

        Attributes
        ----------
        mode : VideoMode
            The video mode of the DMA channel
        """

        def __init__(self, parent, interrupt):
            self._mmio = parent.mmio
            self._frames = AxiVDMA._FrameList(self, 0xAC, parent.framecount)
            self._interrupt = interrupt
            self._sinkchannel = None
            self._mode = None

        def _readframe_internal(self):
            nextframe = self._cache.getframe()
            previous_frame = (self.activeframe + 1) % len(self._frames)
            captured = self._frames[previous_frame]
            self._frames.takeownership(previous_frame)
            self._frames[previous_frame] = nextframe
            self.irqframecount = 1
            return captured

        def readframe(self):
            """Read a frame from the channel and return to the user

            This function may block until a complete frame has been read. A
            single frame buffer is kept so the first frame read after a long
            pause in reading may return a stale frame. To ensure an up-to-date
            frame when starting processing video read an additional time
            before starting the processing loop.

            Returns
            -------
            numpy.ndarray of the video frame

            """
            if not self.running:
                raise RuntimeError('DMA channel not started')
            while self._mmio.read(0x34) & 0x1000 == 0:
                loop = asyncio.get_event_loop()
                loop.run_until_complete(
                    asyncio.ensure_future(self._interrupt.wait()))
            self._mmio.write(0x34, 0x1000)
            return self._readframe_internal()

        async def readframe_async(self):
            """Read a frame from the channel, yielding instead of blocking
            if no data is available. See readframe for more details

            """
            if not self.running:
                raise RuntimeError('DMA channel not started')
            while self._mmio.read(0x34) & 0x1000 == 0:
                await self._interrupt.wait()
            self._mmio.write(0x34, 0x1000)
            return self._readframe_internal()

        @property
        def activeframe(self):
            """The frame index currently being processed by the DMA

            This process requires clearing any error bits in the DMA channel

            """
            self._mmio.write(0x34, 0x4090)
            return (self._mmio.read(0x28) >> 24) & 0x1F

        @property
        def desiredframe(self):
            """The next frame index to the processed by the DMA

            """
            return (self._mmio.read(0x28) >> 8) & 0x1F

        @desiredframe.setter
        def desiredframe(self, frame_number):
            if frame_number < 0 or frame_number >= len(self._frames):
                raise ValueError("Invalid frame index")
            register_value = self._mmio.read(0x28)
            mask = ~(0x1F << 8)
            register_value &= mask
            register_value |= (frame_number << 8)
            self._mmio.write(0x28, register_value)

        @property
        def mode(self):
            """The video mode of the DMA. Must be set prior to starting.
            Changing this while the DMA is running will result in the DMA
            being stopped.

            """
            return self._mode

        @mode.setter
        def mode(self, value):
            if self.running:
                self.stop()
            self._mode = value

        @property
        def running(self):
            """Is the DMA channel running

            """
            return (self._mmio.read(0x34) & 0x1) == 0

        @property
        def parked(self):
            """Is the channel parked or running in circular buffer mode

            """
            return self._mmio.read(0x30) & 0x2 == 0

        @parked.setter
        def parked(self, value):
            register = self._mmio.read(0x30)
            if value:
                register &= ~0x2
            else:
                register |= 0x2
            self._mmio.write(0x30, register)

        @property
        def irqframecount(self):
            register = self._mmio.read(0x30)
            return (register >> 16) & 0xFF

        @irqframecount.setter
        def irqframecount(self, val):
            register = self._mmio.read(0x30)
            newregister = (register & 0xFF00FFFF) | (val << 16)
            if register != newregister:
                self._mmio.write(0x30, newregister)

        def start(self):
            """Start the DMA. The mode must be set prior to this being called

            """
            if not self._mode:
                raise RuntimeError("Video mode not set, channel not started")
            self.desiredframe = 0
            self._cache = _FrameCache(self._mode)
            for i in range(len(self._frames)):
                self._frames[i] = self._cache.getframe()

            self._writemode()
            self.reload()
            self._mmio.write(0x30, 0x00011083)  # Start DMA
            self.irqframecount = 4  # Ensure all frames are written to
            self._mmio.write(0x34, 0x1000)  # Clear any interrupts
            while not self.running:
                pass
            self.reload()
            self.desiredframe = 1

        def stop(self):
            """Stops the DMA, clears the frame cache and unhooks any tied
            outputs

            """
            self.tie(None)
            self._mmio.write(0x30, 0x00011080)
            while self.running:
                pass
            for i in range(len(self._frames)):
                self._frames[i] = None
            if hasattr(self, '_cache'):
                self._cache.clear()

        def _writemode(self):
            self._mmio.write(0xA4, self._mode.width *
                             self._mode.bytes_per_pixel)
            self._mmio.write(0xA8, self._mode.stride)

        def reload(self):
            """Reload the configuration of the DMA. Should only be called
            by the _FrameList class or if you really know what you are doing

            """
            if self.running:
                self._mmio.write(0xA0, self._mode.height)

        def reset(self):
            """Soft reset the DMA. Finishes all transfers before starting
            the reset process

            """
            self.stop()
            self._mmio.write(0x30, 0x00011084)
            while self._mmio.read(0x30) & 0x4 == 4:
                pass

        def tie(self, channel):
            """Ties an output channel to this input channel. This is used
            to pass video from input to output without invoking the CPU
            for each frame. Main use case is when some slow processing is
            being done on a subset of frames while the video is passed
            through directly to the output. Only one output may be tied
            to an output. The tie is broken either by calling tie(None) or
            writing a frame to the tied output channel.

            """
            if self._sinkchannel:
                self._frames.removeslave(self._sinkchannel._frames)
                self._sinkchannel.parked = True
                self._sinkchannel.sourcechannel = None
            self._sinkchannel = channel
            if self._sinkchannel:
                self._frames.addslave(self._sinkchannel._frames)
                self._sinkchannel.parked = False
                self._sinkchannel.framedelay = 1
                self._sinkchannel.sourcechannel = self

    class MM2SChannel:
        """DMA channel from memory to a video output.

        Will continually repeat the most recent frame written.

        Attributes
        ----------
        mode : VideoMode
            Video mode of the DMA channel

        """

        def __init__(self, parent, interrupt):
            self._mmio = parent.mmio
            self._frames = AxiVDMA._FrameList(self, 0x5C, parent.framecount)
            self._interrupt = interrupt
            self._mode = None
            self.sourcechannel = None

        def start(self):
            """Start the DMA channel with a blank screen. The mode must
            be set prior to calling or a RuntimeError will result.

            """
            if not self._mode:
                raise RuntimeError("Video mode not set, channel not started")
            self._cache = _FrameCache(self._mode)
            self._frames[0] = self._cache.getframe()
            self._writemode()
            self.reload()
            self._mmio.write(0x00, 0x00011089)
            while not self.running:
                pass
            self.reload()
            self.desiredframe = 0
            pass

        def stop(self):
            """Stop the DMA channel and empty the frame cache

            """
            self._mmio.write(0x00, 0x00011080)
            while self.running:
                pass
            for i in range(len(self._frames)):
                self._frames[i] = None
            if hasattr(self, '_cache'):
                self._cache.clear()

        def reset(self):
            """Soft reset the DMA channel

            """
            self.stop()
            self._mmio.write(0x00, 0x00011084)
            while self._mmio.read(0x00) & 0x4 == 4:
                pass

        def _writeframe_internal(self, frame):
            if self.sourcechannel:
                self.sourcechannel.tie(None)

            next_frame = (self.desiredframe + 1) % len(self._frames)
            self._frames[next_frame] = frame
            self.desiredframe = next_frame

        def writeframe(self, frame):
            """Schedule the specified frame to be the next one displayed.
            Assumes ownership of frame which should no longer be modified
            by the user. May block if there is already a frame scheduled.

            """
            if not self.running:
                raise RuntimeError('DMA channel not started')
            while self._mmio.read(0x04) & 0x1000 == 0:
                loop = asyncio.get_event_loop()
                loop.run_until_complete(
                    asyncio.ensure_future(self._interrupt.wait()))
            self._mmio.write(0x04, 0x1000)
            self._writeframe_internal(frame)

        async def writeframe_async(self, frame):
            """Same as writeframe() but yields instead of blocking if a
            frame is already scheduled

            """
            if not self.running:
                raise RuntimeError('DMA channel not started')
            while self._mmio.read(0x04) & 0x1000 == 0:
                await self._interrupt.wait()
            self._mmio.write(0x04, 0x1000)
            self._writeframe_internal(frame)

        def setframe(self, frame):
            """Sets a frame without blocking or taking ownership. In most
            circumstances writeframe() is more appropriate

            """
            frameindex = self.desiredframe
            self._frames[frameindex] = frame
            self._frames.takeownership(frameindex)

        def _writemode(self):
            self._mmio.write(0x54, self._mode.width *
                             self._mode.bytes_per_pixel)
            register = self._mmio.read(0x58)
            register &= (0xF << 24)
            register |= self._mode.stride
            self._mmio.write(0x58, register)

        def reload(self):
            """Reload the configuration of the DMA. Should only be called
            by the _FrameList class or if you really know what you are doing

            """
            if self.running:
                self._mmio.write(0x50, self._mode.height)

        def newframe(self):
            """Returns a frame of the appropriate size for the video mode.

            The contents of the frame are undefined and should not be assumed
            to be black

            Returns
            -------
            numpy.ndarray video frame

            """
            return self._cache.getframe()

        @property
        def activeframe(self):
            self._mmio.write(0x04, 0x4090)
            return (self._mmio.read(0x28) >> 16) & 0x1F

        @property
        def desiredframe(self):
            return self._mmio.read(0x28) & 0x1F

        @desiredframe.setter
        def desiredframe(self, frame_number):
            if frame_number < 0 or frame_number >= len(self._frames):
                raise ValueError("Invalid Frame Index")
            register_value = self._mmio.read(0x28)
            mask = ~0x1F
            register_value &= mask
            register_value |= frame_number
            self._mmio.write(0x28, register_value)

        @property
        def running(self):
            return (self._mmio.read(0x04) & 0x1) == 0

        @property
        def mode(self):
            """The video mode of the DMA, must be called prior to starting.
            If changed while the DMA channel is running the channel will be
            stopped

            """
            return self._mode

        @mode.setter
        def mode(self, value):
            if self.running:
                self.stop()
            self._mode = value

        @property
        def parked(self):
            """Is the channel parked or running in circular buffer mode

            """
            return self._mmio.read(0x00) & 0x2 == 0

        @parked.setter
        def parked(self, value):
            register = self._mmio.read(0x00)
            if value:
                self.desiredframe = self.activeframe
                register &= ~0x2
            else:
                register |= 0x2
            self._mmio.write(0x00, register)

        @property
        def framedelay(self):
            register = self._mmio.read(0x58)
            return register >> 24

        @framedelay.setter
        def framedelay(self, value):
            register = self._mmio.read(0x58)
            register &= 0xFFFF
            register |= value << 24
            self._mmio.write(0x58, register)

    def __init__(self, description, framecount=4):
        """Create a new instance of the AXI Video DMA driver

        Parameters
        ----------
        name : str
            The name of the IP core to instantiate the driver for

        """
        super().__init__(description)
        self.framecount = framecount
        self.readchannel = AxiVDMA.S2MMChannel(self, self.s2mm_introut)
        self.writechannel = AxiVDMA.MM2SChannel(self, self.mm2s_introut)

    bindto = ['xilinx.com:ip:axi_vdma:6.2']


class ColorConverter(DefaultIP):
    """Driver for the color space converter

    The colorspace convert implements a 3x4 matrix for performing arbitrary
    linear color conversions. Each coefficient is represented as a 10 bit
    signed fixed point number with 2 integer bits. The result of the
    computation can visualised as a table

    #      in1 in2 in3 1
    # out1  c1  c2  c3 c10
    # out2  c4  c5  c6 c11
    # out3  c7  c8  c9 c12

    The color can be changed mid-stream.

    Attributes
    ----------
    colorspace : list of float
        The coefficients of the colorspace conversion

    """

    def __init__(self, description):
        """Construct an instance of the driver

        Attributes
        ----------
        description : dict
            IP dict entry for the IP core

        """
        super().__init__(description)

    bindto = ['xilinx.com:hls:color_convert:1.0']

    @staticmethod
    def _signextend(value):
        """Sign extend a 10-bit number

        Derived from https://stackoverflow.com/questions/32030412/
                             twos-complement-sign-extension-python

        """
        return (value & 0x1FF) - (value & 0x200)

    @property
    def colorspace(self):
        """The colorspace to convert. See the class description for
        details of the coefficients. The coefficients are a list of
        floats of length 12

        """
        return [ColorConverter._signextend(self.read(0x10 + 8 * i)) / 256
                for i in range(12)]

    @colorspace.setter
    def colorspace(self, color):
        if len(color) != 12:
            raise ValueError("Wrong number of elements in color specification")
        for i, c in enumerate(color):
            self.write(0x10 + 8 * i, int(c * 256))


class PixelPacker(DefaultIP):
    """Driver for the pixel format convert

    Changes the number of bits per pixel in the video stream. The stream
    should be paused prior to the width being changed. This can be targeted
    at either a pixel_pack or a pixel_unpack IP core.For a packer the input
    is always 24 bits per pixel while for an unpacker the output 24 bits per
    pixel.

    """

    def __init__(self, description):
        """Construct an instance of the driver

        Attributes
        ----------
        description : dict
            IP dict entry for the IP core

        """
        super().__init__(description)
        self._bpp = 24
        self.write(0x10, 0)
        self._resample = False

    bindto = ['xilinx.com:hls:pixel_pack:1.0',
              'xilinx.com:hls:pixel_unpack:1.0']

    @property
    def bits_per_pixel(self):
        """Number of bits per pixel in the stream

        Valid values are 8, 24 and 32. The following table describes the
        operation for packing and unpacking for each width

        Mode     Pack                          Unpack
        8  bpp   Keep only the first channel   Pad other channels with 0
        16 bpp   Dependent on resample         Dependent on resample
        24 bpp   No change                     No change
        32 bpp   Pad channel 4 with 0          Discard channel 4

        """
        mode = self.read(0x10)
        if mode == 0:
            return 24
        elif mode == 1:
            return 32
        elif mode == 2:
            return 8
        elif mode <= 4:
            return 16

    @bits_per_pixel.setter
    def bits_per_pixel(self, value):
        if value == 24:
            mode = 0
        elif value == 32:
            mode = 1
        elif value == 8:
            mode = 2
        elif value == 16:
            if self._resample:
                mode = 4
            else:
                mode = 3
        else:
            raise ValueError("Bits per pixel must be 8, 16, 24 or 32")
        self._bpp = value
        self.write(0x10, mode)

    @property
    def resample(self):
        """Perform chroma resampling in 16 bpp mode

        Boolean property that only affects 16 bpp mode. If True then
        the two chroma channels are multiplexed on to the second output
        pixel, otherwise only the first and second channels are transferred
        and the third is discarded
        """
        return self._resample

    @resample.setter
    def resample(self, value):
        self._resample = value
        # Make sure the mode is updated
        if self.bits_per_pixel == 16:
            self.bits_per_pixel = 16


COLOR_IN_BGR = [1, 0, 0,
                0, 1, 0,
                0, 0, 1,
                0, 0, 0]

COLOR_OUT_BGR = [1, 0, 0,
                 0, 1, 0,
                 0, 0, 1,
                 0, 0, 0]

COLOR_IN_RGB = [0, 0, 1,
                0, 1, 0,
                1, 0, 0,
                0, 0, 0]

COLOR_OUT_RGB = [0, 0, 1,
                 0, 1, 0,
                 1, 0, 0,
                 0, 0, 0]

COLOR_IN_YCBCR = [0.114, 0.587, 0.299,
                  0.5, -0.331264, -0.168736,
                  -0.081312, -0.41866, 0.5,
                  0, 0.5, 0.5]

COLOR_OUT_YCBCR = [1, 1.772, 0,
                   1, -0.3344136, -0.714136,
                   1, 0, 1.402,
                   -0.886, 0.529136, -0.701]

COLOR_OUT_GRAY = [1, 0, 0,
                  1, 0, 0,
                  1, 0, 0,
                  0, 0, 0]


class PixelFormat:
    """Wrapper for all of the information about a video format

    Attributes
    ----------
    bits_per_pixel : int
        Number of bits for each pixel
    in_color : list of float
        Coefficients from BGR stream to pixel format
    out_color : list of float
        Coefficient from pixel format to BGR stream

    """

    def __init__(self, bits_per_pixel, in_color, out_color):
        self.bits_per_pixel = bits_per_pixel
        self.in_color = in_color
        self.out_color = out_color


PIXEL_RGB = PixelFormat(24, COLOR_IN_RGB, COLOR_OUT_RGB)
PIXEL_RGBA = PixelFormat(32, COLOR_IN_RGB, COLOR_OUT_RGB)
PIXEL_BGR = PixelFormat(24, COLOR_IN_BGR, COLOR_OUT_BGR)
PIXEL_YCBCR = PixelFormat(24, COLOR_IN_YCBCR, COLOR_OUT_YCBCR)
PIXEL_GRAY = PixelFormat(8, COLOR_IN_YCBCR, COLOR_OUT_GRAY)


class HDMIIn(DefaultHierarchy):
    """Wrapper for the input video pipeline of the Pynq-Z1 base overlay

    This wrapper assumes the following pipeline structure and naming

    color_convert_in -> pixel_pack ->axi_vdma
    with vtc_in and axi_gpio_hdmiiin helper IP

    Attributes
    ----------
    frontend : pynq.lib.video.HDMIInFrontend
        The HDMI frontend for signal detection
    color_convert : pynq.lib.video.ColorConverter
        The input color format converter
    pixel_pack : pynq.lib.video.PixelPacker
        Converts the input pixel size to that required by the VDMA

    """

    @staticmethod
    def checkhierarchy(description):
        if 'frontend' in description['hierarchies']:
            frontend_dict = description['hierarchies']['frontend']
        else:
            return False
        return (
            'pixel_pack' in description['ip'] and
            'color_convert' in description['ip'] and
            description['ip']['pixel_pack']['driver'] == PixelPacker and
            description['ip']['color_convert']['driver'] == ColorConverter and
            HDMIInFrontend.checkhierarchy(frontend_dict))

    def __init__(self, description, vdma=None):
        """Initialise the drivers for the pipeline

        Parameters
        ----------
        path : str
            name of the hierarchy containing all of the video blocks

        """
        super().__init__(description)
        ip_dict = self.description
        self._vdma = vdma
        self._color = self.color_convert
        self._pixel = self.pixel_pack
        self._hdmi = self.frontend

    def configure(self, pixelformat=PIXEL_BGR):
        """Configure the pipeline to use the specified pixel format.

        If the pipeline is running it is stopped prior to the configuration
        being changed

        Parameters
        ----------
        pixelformat : PixelFormat
            The pixel format to configure the pipeline for

        """
        if self._vdma.readchannel.running:
            self._vdma.readchannel.stop()
        self._color.colorspace = pixelformat.in_color
        self._pixel.bits_per_pixel = pixelformat.bits_per_pixel
        self._hdmi.start()
        input_mode = self._hdmi.mode
        self._vdma.readchannel.mode = VideoMode(input_mode.width,
                                                input_mode.height,
                                                pixelformat.bits_per_pixel)
        return self._closecontextmanager()

    def start(self):
        """Start the pipeline

        """
        self._vdma.readchannel.start()
        return self._stopcontextmanager()

    def stop(self):
        """Stop the pipeline

        """
        self._vdma.readchannel.stop()

    @contextlib.contextmanager
    def _stopcontextmanager(self):
        """Context Manager to stop the VDMA at the end of the block

        """
        yield
        self.stop()

    @contextlib.contextmanager
    def _closecontextmanager(self):
        """Context Manager to close the HDMI port at the end of the block

        """
        yield
        self.close()

    def close(self):
        """Uninitialise the drivers, stopping the pipeline beforehand

        """
        self.stop()
        self._hdmi.stop()

    @property
    def colorspace(self):
        """The colorspace of the pipeline, can be changed without stopping
        the pipeline

        """
        return self._color.colorspace

    @colorspace.setter
    def colorspace(self, new_colorspace):
        self._color.colorspace = new_colorspace

    @property
    def mode(self):
        """Video mode of the input

        """
        return self._vdma.readchannel.mode

    def readframe(self):
        """Read a video frame

        See AxiVDMA.S2MMChannel.readframe for details

        """
        return self._vdma.readchannel.readframe()

    async def readframe_async(self):
        """Read a video frame

        See AxiVDMA.S2MMChannel.readframe for details

        """
        return await self._vdma.readchannel.readframe_async()

    def tie(self, output):
        """Mirror the video input on to an output channel

        Parameters
        ----------
        output : HDMIOut
            The output to mirror on to

        """
        self._vdma.readchannel.tie(output._vdma.writechannel)


class HDMIOut(DefaultHierarchy):
    """Wrapper for the output video pipeline of the Pynq-Z1 base overlay

    This wrapper assumes the following pipeline structure and naming

    axi_vdma -> pixel_unpack -> color_convert -> frontend
    with vtc_out and axi_dynclk helper IP

    Attributes
    ----------
    frontend : pynq.lib.video.HDMIOutFrontend
        The HDMI frontend for mode setting
    color_convert : pynq.lib.video.ColorConverter
        The output color format converter
    pixel_unpack : pynq.lib.video.PixelPacker
        Converts the input pixel size to 24 bits-per-pixel

    """

    @staticmethod
    def checkhierarchy(description):
        if 'frontend' in description['hierarchies']:
            frontend_hierarchy = description['hierarchies']['frontend']
        else:
            return False
        return (
            'pixel_unpack' in description['ip'] and
            'color_convert' in description['ip'] and
            description['ip']['pixel_unpack']['driver'] == PixelPacker and
            description['ip']['color_convert']['driver'] == ColorConverter and
            HDMIOutFrontend.checkhierarchy(frontend_hierarchy))

    def __init__(self, description, vdma=None):
        """Initialise the drivers for the pipeline

        Parameters
        ----------
        path : str
            name of the hierarchy containing all of the video blocks

        """
        super().__init__(description)
        self._vdma = vdma
        self._color = self.color_convert
        self._pixel = self.pixel_unpack
        self._hdmi = self.frontend

    def configure(self, mode, pixelformat=None):
        """Configure the pipeline to use the specified pixel format and size.

        If the pipeline is running it is stopped prior to the configuration
        being changed

        Parameters
        ----------
        mode : VideoMode
            The video mode to output
        pixelformat : PixelFormat
            The pixel format to configure the pipeline for

        """
        if self._vdma.writechannel.running:
            self._vdma.writechannel.stop()
        if pixelformat is None:
            if mode.bits_per_pixel == 8:
                pixelformat = PIXEL_GRAY
            elif mode.bits_per_pixel == 24:
                pixelformat = PIXEL_BGR
            elif mode.bits_per_pixel == 32:
                pixelformat = PIXEL_RGBA
            else:
                raise ValueError(
                    "No default pixel format for ${mode.bits_per_pixel} bpp")
        if pixelformat.bits_per_pixel != mode.bits_per_pixel:
            raise ValueError(
                "Video mode and pixel format have different sized pixels")

        self._color.colorspace = pixelformat.out_color
        self._pixel.bits_per_pixel = pixelformat.bits_per_pixel
        self._hdmi.mode = mode
        self._vdma.writechannel.mode = mode
        self._hdmi.start()
        return self._closecontextmanager()

    def start(self):
        """Start the pipeline

        """
        self._vdma.writechannel.start()
        return self._stopcontextmanager()

    def stop(self):
        """Stop the pipeline

        """
        self._vdma.writechannel.stop()

    def close(self):
        """Close the pipeline an unintialise the drivers

        """
        self.stop()
        self._hdmi.stop()

    @contextlib.contextmanager
    def _stopcontextmanager(self):
        """Context Manager to stop the VDMA at the end of the block

        """
        yield
        self.stop()

    @contextlib.contextmanager
    def _closecontextmanager(self):
        """Context Manager to close the HDMI port at the end of the block

        """
        yield
        self.close()

    @property
    def colorspace(self):
        """Set the colorspace for the pipeline - can be done without
        stopping the pipeline

        """
        return self._color.colorspace

    @colorspace.setter
    def colorspace(self, new_colorspace):
        self._color.colorspace = new_colorspace

    @property
    def mode(self):
        """The currently configured video mode

        """
        return self._vdma.writechannel.mode

    def newframe(self):
        """Return an unintialised video frame of the correct type for the
        pipeline

        """
        return self._vdma.writechannel.newframe()

    def writeframe(self, frame):
        """Write the frame to the video output

        See AxiVDMA.MM2SChannel.writeframe for more details

        """
        self._vdma.writechannel.writeframe(frame)

    async def writeframe_async(self, frame):
        """Write the frame to the video output

        See AxiVDMA.MM2SChannel.writeframe for more details

        """
        await self._vdma.writechannel.writeframe_async(frame)


class HDMIWrapper(DefaultHierarchy):
    """Hierarchy driver for the entire Pynq-Z1 video subsystem.

    Exposes the input, output and video DMA as attributes. For most
    use cases the wrappers for the input and output pipelines are
    sufficient and the VDMA will not need to be used directly.

    Attributes
    ----------
    hdmi_in : pynq.lib.video.HDMIIn
        The HDMI input pipeline
    hdmi_out : pynq.lib.video.HDMIOut
        The HDMI output pipeline
    axi_vdma : pynq.lib.video.AxiVDMA
        The video DMA.

    """
    @staticmethod
    def checkhierarchy(description):
        if 'hdmi_in' in description['hierarchies']:
            in_dict = description['hierarchies']['hdmi_in']
        else:
            return False
        if 'hdmi_out' in description['hierarchies']:
            out_dict = description['hierarchies']['hdmi_out']
        else:
            return False
        return ('axi_vdma' in description['ip'] and
                description['ip']['axi_vdma']['driver'] == AxiVDMA and
                HDMIIn.checkhierarchy(in_dict) and
                HDMIOut.checkhierarchy(out_dict))

    def __init__(self, description):
        super().__init__(description)
        in_dict = description['hierarchies']['hdmi_in']
        out_dict = description['hierarchies']['hdmi_out']
        self.hdmi_in = HDMIIn(in_dict, self.axi_vdma)
        self.hdmi_out = HDMIOut(out_dict, self.axi_vdma)
