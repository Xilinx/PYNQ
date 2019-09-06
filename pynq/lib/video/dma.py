#   Copyright (c) 2018, Xilinx, Inc.
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

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

import asyncio
import numpy as np
from pynq.xlnk import ContiguousArray
from pynq import DefaultIP, allocate


class _FrameCache:
    def __init__(self, mode, capacity=5, cacheable=0):
        self._cache = []
        self._mode = mode
        self._capacity = capacity
        self._cacheable = cacheable

    def getframe(self):
        """Retrieve a frame from the cache or create a new frame if the
        cache is empty. The freebuffer method of the returned array is
        overriden to return the object to the cache rather than freeing
        the object.

        """
        if self._cache:
            frame = allocate(
                shape=self._mode.shape, dtype='u1', cacheable=self._cacheable,
                pointer=self._cache.pop(), cache=self)
        else:
            frame = allocate(
                shape=self._mode.shape, dtype=np.uint8,
                cacheable=self._cacheable, cache=self)
        return frame

    def return_pointer(self, pointer):
        if len(self._cache) < self._capacity:
            self._cache.append(pointer)

    def clear(self):
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
        cacheable_frames : bool
            Whether frames should be stored in cacheable or
            non-cacheable memory

        """

        def __init__(self, parent, interrupt):
            self._mmio = parent.mmio
            self._frames = AxiVDMA._FrameList(self, 0xAC, parent.framecount)
            self._interrupt = interrupt
            self._sinkchannel = None
            self._mode = None
            self.cacheable_frames = True

        def _readframe_internal(self):
            if self._mmio.read(0x34) & 0x8980:
                # Some spurious errors can occur at the start of transfers
                # let's ignore them for now
                self._mmio.write(0x34, 0x8980)
            self.irqframecount = 1
            nextframe = self._cache.getframe()
            previous_frame = (self.activeframe + 2) % len(self._frames)
            captured = self._frames[previous_frame]
            self._frames.takeownership(previous_frame)
            self._frames[previous_frame] = nextframe
            post_frame = (self.activeframe + 2) % len(self._frames)
            captured.invalidate()
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
                pass
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
            self._cache = _FrameCache(
                    self._mode, cacheable=self.cacheable_frames)
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
        cacheable_frames : bool
            Whether frames should be stored in cacheable or
            non-cacheable memory

        """

        def __init__(self, parent, interrupt):
            self._mmio = parent.mmio
            self._frames = AxiVDMA._FrameList(self, 0x5C, parent.framecount)
            self._interrupt = interrupt
            self._mode = None
            self.sourcechannel = None
            self.cacheable_frames = True

        def start(self):
            """Start the DMA channel with a blank screen. The mode must
            be set prior to calling or a RuntimeError will result.

            """
            if not self._mode:
                raise RuntimeError("Video mode not set, channel not started")
            self._cache = _FrameCache(
                    self._mode, cacheable=self.cacheable_frames)
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

            frame.flush()
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

    bindto = ['xilinx.com:ip:axi_vdma:6.2',
              'xilinx.com:ip:axi_vdma:6.3']
