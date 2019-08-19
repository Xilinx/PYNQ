#   Copyright (c) 2017, Xilinx, Inc.
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

from pynq import DefaultIP
import warnings


__author__ = 'Peter Ogden, Anurag Dubey'
__copyright__ = 'Copyright 2017, Xilinx'
__email__ = 'pynq_support@xilinx.com'


MAX_C_SG_LENGTH_WIDTH = 26


class _DMAChannel:
    """Drives a single channel of the Xilinx AXI DMA

    This driver is designed to be used in conjunction with the
    `pynq.allocate()` method of memory allocation. The channel has
    main functions `transfer` and `wait` which start and wait for
    the transfer to finish respectively. If interrupts are enabled
    there is also a `wait_async` coroutine.

    This class should not be constructed directly, instead used
    through the AxiDMA class.

    """
    def __init__(self, mmio, offset, size, flush_before, interrupt=None):
        self._mmio = mmio
        self._offset = offset
        self._interrupt = interrupt
        self._flush_before = flush_before
        self._size = size
        self._active_buffer = None
        self._first_transfer = True
        self.start()

    @property
    def running(self):
        """True if the DMA engine is currently running

        """
        return self._mmio.read(self._offset + 4) & 0x01 == 0x00

    @property
    def idle(self):
        """True if the DMA engine is idle

        `transfer` can only be called when the DMA is idle

        """
        return self._mmio.read(self._offset + 4) & 0x02 == 0x02

    def start(self):
        """Start the DMA engine if stopped

        """
        if self._interrupt:
            self._mmio.write(self._offset, 0x1001)
        else:
            self._mmio.write(self._offset, 0x0001)
        while not self.running:
            pass
        self._first_transfer = True

    def stop(self):
        """Stops the DMA channel and aborts the current transfer

        """
        self._mmio.write(self._offset, 0x0000)
        while self.running:
            pass

    def _clear_interrupt(self):
        self._mmio.write(self._offset + 4, 0x1000)

    def transfer(self, array):
        """Transfer memory with the DMA

        Transfer must only be called when the channel is idle.

        Parameters
        ----------
        array : ContiguousArray
            An xlnk allocated array to be transferred

        """
        if array.nbytes > self._size:
            raise ValueError('Transferred array is {} bytes, which exceeds '
                             'the maximum DMA buffer size {}.'.format(
                              array.nbytes, self._size))
        if not self.running:
            raise RuntimeError('DMA channel not started')
        if not self.idle and not self._first_transfer:
            raise RuntimeError('DMA channel not idle')
        if self._flush_before:
            array.flush()
        self._mmio.write(self._offset + 0x18, array.physical_address)
        self._mmio.write(self._offset + 0x28, array.nbytes)
        self._active_buffer = array
        self._first_transfer = False

    def wait(self):
        """Wait for the transfer to complete

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        while not self.idle:
            pass
        if not self._flush_before:
            self._active_buffer.invalidate()

    async def wait_async(self):
        """Wait for the transfer to complete

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        while not self.idle:
            await self._interrupt.wait()
        self._clear_interrupt()
        if not self._flush_before:
            self._active_buffer.invalidate()


class DMA(DefaultIP):
    """Class for Interacting with the AXI Simple DMA Engine

    This class provides two attributes for the read and write channels.
    The read channel copies data from the stream into memory and
    the write channel copies data from memory to the output stream.
    Both channels have an identical API consisting of `transfer` and
    `wait` functions. If interrupts have been enabled and connected
    for the DMA engine then `wait_async` is also present.

    Buffers to be transferred must be a `PynqBuffer` objectedallocated
    through `pynq.allocate()` function either directly or indirectly. This
    means that Frames from the video subsystem can be transferred using
    this class.

    Attributes
    ----------
    recvchannel : _DMAChannel
        The stream to memory channel
    sendchannel : _DMAChannel
        The memory to stream channel

    """
    def __init__(self, description, *args, **kwargs):
        """Create an instance of the DMA Driver

        Parameters
        ----------
        description : dict
            The entry in the IP dict describing the DMA engine

        """
        if type(description) is not dict or args or kwargs:
            raise RuntimeError('You appear to want the old DMA driver which '
                               'has been deprecated and moved to '
                               'pynq.lib.deprecated')
        super().__init__(description=description)

        if 'parameters' in description and \
                'c_sg_length_width' in description['parameters']:
            self.buffer_max_size = \
                1 << int(description['parameters']['c_sg_length_width'])
        else:
            self.buffer_max_size = 1 << MAX_C_SG_LENGTH_WIDTH
            message = 'Failed to find parameter c_sg_length_width; ' \
                      'users should really use *.hwh files for overlays.'
            warnings.warn(message, UserWarning)

        if 'mm2s_introut' in description['interrupts']:
            self.sendchannel = _DMAChannel(self.mmio, 0x0,
                                           self.buffer_max_size,
                                           True, self.mm2s_introut)
        else:
            self.sendchannel = _DMAChannel(self.mmio, 0x0,
                                           self.buffer_max_size,
                                           True)

        if 's2mm_introut' in description['interrupts']:
            self.recvchannel = _DMAChannel(self.mmio, 0x30,
                                           self.buffer_max_size,
                                           False, self.s2mm_introut)
        else:
            self.recvchannel = _DMAChannel(self.mmio, 0x30,
                                           self.buffer_max_size,
                                           False)

    bindto = ['xilinx.com:ip:axi_dma:7.1']
