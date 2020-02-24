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
from pynq import Xlnk
import numpy
import warnings

__author__ = 'Peter Ogden, Anurag Dubey'
__copyright__ = 'Copyright 2017, Xilinx'
__email__ = 'pynq_support@xilinx.com'


MAX_C_SG_LENGTH_WIDTH = 26
DMA_TYPE_TX = 1
DMA_TYPE_RX = 0

class _SDMAChannel:
    """Drives a single channel of the Xilinx AXI Simple DMA

    This driver is designed to be used in conjunction with the
    `pynq.allocate()` method of memory allocation. The channel has
    main functions `transfer` and `wait` which start and wait for
    the transfer to finish respectively. If interrupts are enabled
    there is also a `wait_async` coroutine.

    This class should not be constructed directly, instead used
    through the AxiDMA class.

    """
    def __init__(self, mmio, max_size, width, tx_rx, dre, interrupt=None):
        self._mmio = mmio
        self._interrupt = interrupt
        self._max_size = max_size
        self._active_buffer = None
        self._first_transfer = True
        self._align = 1 << int(width)
        self._tx_rx = tx_rx
        self._dre = dre

        if (tx_rx == DMA_TYPE_RX):
            self._offset = 0x30
            self._flush_before = False
        else:
            self._offset = 0
            self._flush_before = True

        self.transferred = 0
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

    @property
    def error(self):
        """True if DMA engine is in an error state
        """
        return self._mmio.read(self._offset + 4) & 0x70 != 0x0

    def start(self):
        """Start the DMA engine if stopped

        """
        if self._interrupt:
            self._mmio.write(self._offset, 0x1001) # XXX what about errors?
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
        self._mmio.write(self._offset + 4, 0x1000) # XXX what about errors?

    def transfer(self, array, start=0, nbytes=0):
        """Transfer memory with the DMA

        Transfer must only be called when the channel is idle.

        Parameters
        ----------
        array : ContiguousArray
            An xlnk allocated array to be transferred
        start : integer (optional, default 0)
             Offset into array to start
        nbytes : integer (optional, default 0)
             Number of bytes to transfer.  0 means everything after the starting point.

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        if not self.idle and not self._first_transfer:
            raise RuntimeError('DMA channel not idle')
        if nbytes == 0:
            nbytes = array.nbytes - start
        if (nbytes > self._max_size):
            raise ValueError('Transfer size is {} bytes, which exceeds '
                             'the maximum DMA buffer size {}.'.format(
                              nbytes, self._max_size))
        # In simple mode, start address must be data bus width aligned.
        if not self._dre and ((array.physical_address + start) % self._align) != 0:
            raise RuntimeError('DMA does not support unaligned transfers; '
                               'Starting address must be 64-byte aligned!')
        if self._flush_before:
            array.flush()
        self.transferred = 0
        self._mmio.write(self._offset + 0x18, (array.physical_address + start) & 0xffffffff)
        self._mmio.write(self._offset + 0x1C, ((array.physical_address + start) >> 32) & 0xffffffff)
        self._mmio.write(self._offset + 0x28, nbytes)
        self._active_buffer = array
        self._first_transfer = False

    def wait(self):
        """Wait for the transfer to complete

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        while True:
            error = self._mmio.read(self._offset + 4)
            if self.error:
                if error & 0x10:
                    raise RuntimeError('DMA Internal Error (transfer length 0?)')
                if error & 0x20:
                    raise RuntimeError('DMA Slave Error (cannot access memory map interface)')
                if error & 0x40:
                    raise RuntimeError('DMA Decode Error (invalid address)')
            if self.idle:
                break
        if not self._flush_before:
            self._active_buffer.invalidate()
        self.transferred = self._mmio.read(self._offset + 0x28)

    async def wait_async(self):
        """Wait for the transfer to complete

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        while not self.idle:
            await self._interrupt.wait()
            # XXX error handling
        self._clear_interrupt()
        if not self._flush_before:
            self._active_buffer.invalidate()
        self.transferred = self._mmio.read(self._offset + 0x28)

class _SGDMAChannel:
    """Drives a single channel of the Xilinx AXI Scatter-Gather DMA

    This driver is designed to be used in conjunction with the
    `pynq.allocate()` method of memory allocation. The channel has
    main functions `transfer` and `wait` which start and wait for
    the transfer to finish respectively. If interrupts are enabled
    there is also a `wait_async` coroutine.

    This class should not be constructed directly, instead used
    through the AxiDMA class.

    """
    def __init__(self, mmio, max_size, width, tx_rx, dre, xlnk, interrupt=None):
        self._mmio = mmio
        self._interrupt = interrupt
        self._max_size = max_size
        self._active_buffer = None
        self._first_transfer = True
        self._align = 1 << int(width)
        self._tx_rx = tx_rx
        self._dre = dre

        if (tx_rx == DMA_TYPE_RX):
            self._offset = 0x30
            self._flush_before = False
        else:
            self._offset = 0
            self._flush_before = True

        self.transferred = 0
        self._descr = None
        self._xlnk = xlnk

        # Ensure engine is stopped
        # XXX bail if busy?
        self.stop()

    @property
    def running(self):
        """True if the DMA engine is currently running

        """
        return self._mmio.read(self._offset + 4) & 0x01 == 0x00

    @property
    def halted(self):
        """True if the DMA engine is halted.

        `transfer` can only be called when the DMA is halted

        """
        return self._mmio.read(self._offset + 4) & 0x01 == 0x1

    @property
    def idle(self):
        """True if the DMA engine is idle

        `transfer` can only be called when the DMA is idle

        """
        return self._mmio.read(self._offset + 4) & 0x02 == 0x02

    @property
    def error(self):
        """True if DMA engine is in an error state
        """
        return self._mmio.read(self._offset + 4) & 0x770 != 0x0

    def start(self):
        """Start the DMA engine if stopped

        """
        self._first_transfer = False
        if self._interrupt:
            self._mmio.write(self._offset, 0x1001) # XXX What about ERRORs?
        else:
            self._mmio.write(self._offset, 0x0001)
        while not self.running:
            pass

    def stop(self):
        """Stops the DMA channel and aborts the current transfer

        """
        self._mmio.write(self._offset, 0x0000)
        while self.running:
            pass
        self._first_transfer = True

    def _clear_interrupt(self):
        self._mmio.write(self._offset + 4, 0x1000) # XXX ERRORs!

    def transfer(self, array, start=0, nbytes=0):
        """Transfer memory with the DMA

        Transfer must only be called when the channel is halted

        Parameters
        ----------
        array : ContiguousArray
            An xlnk allocated array to be transferred
        start : integer (optional, default 0)
             Offset into array to start
        nbytes : integer (optional, default 0)
             Number of bytes to transfer.  0 means everything after the starting point.

        """

        if not self.halted and not self._first_transfer:
            raise RuntimeError('DMA channel not halted')
        if nbytes == 0:
            nbytes = array.nbytes - start
        if not self._dre and ((array.physical_address + start) % self._align) != 0:
            raise RuntimeError('DMA does not support unaligned transfers; '
                               'Starting address must be 64-byte aligned!')

        # Figure out largest possible block size, and the number of descriptors needed
        remain = nbytes
        blkSize = self._max_size - (self._max_size % self._align)

        # We need to always have at least two descriptors!
        if blkSize > remain:
            blkSize = int(remain / 2)
            blkSize -= (blkSize % self._align)

        self._nDesc = int((remain + (blkSize - 1)) / blkSize)

        # Zero-Allocate buffer for descriptors: uint32[nDesc][16]
        # Descriptor is only 52 bytes but each one has to be 64-byte aligned!
        self._descr = self._xlnk.cma_array(shape=(self._nDesc,16),dtype=numpy.uint32)

        # Idle DMA engine
        self.stop()

        # Fill out descriptors
        for i in range(0,self._nDesc):
            # Next descriptor (64-bit)
            self._descr[i, 0] = (self._descr.physical_address + (((i + 1) % self._nDesc) * 16 * 4)) & 0xffffffff
            self._descr[i, 1] = (self._descr.physical_address + (((i + 1) % self._nDesc) * 16 * 4) >> 32) & 0xffffffff


            # Buffer length
            if (remain > blkSize):
                dLen = blkSize
            else:
                dLen = remain
            self._descr[i, 6] = dLen

            remain -= dLen

            # Buffer address (64-bit)
            self._descr[i, 2] = (array.physical_address + (i * blkSize)) & 0xffffffff
            self._descr[i, 3] = ((array.physical_address + (i * blkSize)) >> 32) & 0xffffffff

            # First block
            if i == 0:
                self._descr[i, 6] |= (1 << 27) # SoF (Micro mode only?)

            # Last Block
            if remain == 0:
                self._descr[i, 6] |= (1 << 26) # EoF (Micro mode only?)

        if self._flush_before:
            array.flush()

        # Flush DMA descriptors
        self._descr.flush()

        # Write firstdesc
        self._mmio.write(self._offset + 0x08, self._descr.physical_address & 0xffffffff)
        self._mmio.write(self._offset + 0x0c, (self._descr.physical_address >> 32) & 0xffffffff)

        self._active_buffer = array

        # Let's go!
        self.transferred = 0
        self.start()

        # Writing last desc triggers the descriptor fetches
        self._mmio.write(self._offset + 0x10, (self._descr.physical_address + ((self._nDesc -1) * 16 * 4)) & 0xffffffff)
        self._mmio.write(self._offset + 0x14, ((self._descr.physical_address + ((self._nDesc -1) * 16 * 4)) >> 32) & 0xffffffff)

    def wait(self):
        """Wait for the transfer to complete

        """
        if not self.running and self._first_transfer:
            raise RuntimeError('DMA channel not started')
        while True:
            if self.error:
                error = self._mmio.read(self._offset + 4)
                if error & 0x10:
                    raise RuntimeError('DMA Internal Error (transfer length 0?)')
                if error & 0x20:
                    raise RuntimeError('DMA Slave Error (cannot access memory map interface)')
                if error & 0x40:
                    raise RuntimeError('DMA Decode Error (invalid address)')
                if error & 0x100:
                    raise RuntimeError('Scatter-Gather Internal Error (re-used completed descriptor)')
                if error & 0x200:
                    raise RuntimeError('Scatter-Gather Slave Error (cannot access memory map interface)')
                if error & 0x400:
                    raise RuntimeError('Scatter-Gather Decode Error (invalid descriptor address)')
            if self.idle or self.halted:
                break
        if not self._flush_before:
            self._active_buffer.invalidate()

        # Work out transferred length
        self._descr.flush()
        self.transferred = 0
        for i in range(0,self._nDesc):
            # XXX if micro mode, this doesn't apply.  Count descriptors instead.
            if self._descr[i,7] & 0x30000000:
                raise RuntimeError('DMA Error in descriptor') # XXX Fill in details
            self.transferred += self._descr[i, 7] & 0x03ffffff

        # Ensure engine is idled
        self.stop()

        # Clean up descriptor buffer
        self._descr.close()
        self._descr = None

    async def wait_async(self):
        """Wait for the transfer to complete

        """
        if not self.running and self._first_transfer:
            raise RuntimeError('DMA channel not started')
        while not (self.idle or self.halted):
            await self._interrupt.wait()
        self._clear_interrupt()
        if not self._flush_before:
            self._active_buffer.invalidate()

        # Work out transferred length
        self._descr.flush()
        self.transferred = 0
        for i in range(0,self._nDesc):
            # XXX if micro mode, this doesn't apply.  Count descriptors instead.
            if self._descr[i,7] & 0x30000000:
                raise RuntimeError('DMA Error in descriptor')  # XXX fill in details
            self.transferred += self._descr[i, 7] & 0x03ffffff

        # Ensure engine is idled
        self.stop()

        # Clean up descriptor buffer
        self._descr.close()
        self._descr = None

class DMA(DefaultIP):
    """Class for Interacting with the AXI Simple DMA Engine

    This class provides two attributes for the read and write channels.
    The read channel copies data from the stream into memory and
    the write channel copies data from memory to the output stream.
    Both channels have an identical API consisting of `transfer` and
    `wait` functions. If interrupts have been enabled and connected
    for the DMA engine then `wait_async` is also present.

    Buffers to be transferred must be a `PynqBuffer` object allocated
    through `pynq.allocate()` function either directly or indirectly. This
    means that Frames from the video subsystem can be transferred using
    this class.

    Attributes
    ----------
    recvchannel : _SDMAChannel or _SGDMAChannel
        The stream to memory channel  (if enabled in hardware)
    sendchannel : _SDMAChannel or _SGDMAChannel
        The memory to stream channel  (if enabled in hardware)

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

        # If we can't look this stuff up, then simply bail.
        if 'parameters' not in description:
            message = 'unable to get parameters in description; ' \
                'users should really use *.hwh files for overlays.'
            raise RuntimeError('Unable to get paramters from description; '
                               'Users must use *.hwh files for overlays.');

        if 'c_micro_dma' in description['parameters']:
            self._micro = bool(int(description['parameters']['c_micro_dma']));
        else:
            self._micro = False

        if 'c_include_sg' in description['parameters']:
            self._sg = bool(int(description['parameters']['c_include_sg']));
            xlnk = Xlnk()
        else:
            self._sg = False

        if self._micro and self._sg:
            raise UnsupportedConfiguration('Micro and Scatter-gather modes not supported simultaneously.')

        if 'c_sg_length_width' in description['parameters']:
            self.buffer_max_size = 1 << int(description['parameters']['c_sg_length_width'])
        else:
            self.buffer_max_size = 1 << MAX_C_SG_LENGTH_WIDTH

        # Max transfer length is actually 2^sg_length_width -1  (See PG021 tables 2-15, 2-25, 2-31 and 2-38)
        self.buffer_max_size -= 1

        # Set up Transmit DMA channel, if enabled
        if 'c_include_mm2s' in description['parameters'] and bool(int(description['parameters']['c_include_mm2s'])):
            if 'c_include_mm2s_dre' in description['parameters']:
                dre = bool(int(description['parameters']['c_include_mm2s_dre']))
            else:
                dre = False;

            data_width = int(description['parameters']['c_m_axi_mm2s_data_width']) / 8

            # Work out max transfer size:
            if self._micro:
                max_size = data_width * int(description['parameters']['c_mm2s_burst_size'])
            else:
                max_size = self.buffer_max_size

            # Create the channel
            if 'mm2s_introut' in description['interrupts']:
                if self._sg:
                    self.sendchannel = _SGDMAChannel(self.mmio,
                                                     max_size, 6,
                                                     DMA_TYPE_TX, dre, xlnk,
                                                     self.mm2s_introut)
                else:
                    self.sendchannel = _SDMAChannel(self.mmio,
                                                    max_size, data_width,
                                                    DMA_TYPE_TX, dre,
                                                    self.mm2s_introut)
            else:
                if self._sg:
                    self.sendchannel = _SGDMAChannel(self.mmio,
                                                     max_size, 6,
                                                     DMA_TYPE_TX, dre, xlnk)
                else:
                    self.sendchannel = _SDMAChannel(self.mmio,
                                                    max_size, data_width,
                                                    DMA_TYPE_TX, dre)

        # Set up Receive DMA channel, if enabled
        if 'c_include_s2mm' in description['parameters'] and bool(int(description['parameters']['c_include_s2mm'])):
            if 'c_include_s2mm_dre' in description['parameters']:
                dre = bool(int(description['parameters']['c_include_s2mm_dre']))
            else:
                dre = False;

            data_width = int(description['parameters']['c_m_axi_s2mm_data_width']) / 8

            # Work out max transfer size:
            if self._micro:
                max_size = data_width * int(description['parameters']['c_s2mm_burst_size'])
            else:
                max_size = self.buffer_max_size

            if 's2mm_introut' in description['interrupts']:
                if self._sg:
                    self.recvchannel = _SGDMAChannel(self.mmio,
                                                     max_size, 6,
                                                     DMA_TYPE_RX, dre, xlnk,
                                                     self.s2mm_introut)
                else:
                    self.recvchannel = _SDMAChannel(self.mmio,
                                                    max_size, data_width,
                                                    DMA_TYPE_RX, dre,
                                                    self.s2mm_introut)
            else:
                if self._sg:
                    self.recvchannel = _SGDMAChannel(self.mmio,
                                                     max_size, 6,
                                                     DMA_TYPE_RX, dre, xlnk)
                else:
                    self.recvchannel = _SDMAChannel(self.mmio,
                                                    max_size, data_width,
                                                    DMA_TYPE_RX, dre)

    bindto = ['xilinx.com:ip:axi_dma:7.1']
