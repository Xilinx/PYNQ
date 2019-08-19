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

import os
import mmap
import numpy as np
import pynq.tinynumpy as tnp

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class _AccessHook:
    def __init__(self, baseaddress, device):
        self.baseaddress = baseaddress
        self.device = device

    def read(self, offset, length):
        return self.device.read_registers(self.baseaddress + offset, length)

    def write(self, offset, data):
        self.device.write_registers(self.baseaddress + offset, data)

class MMIO:
    """ This class exposes API for MMIO read and write.

    Attributes
    ----------
    base_addr : int
        The base address, not necessarily page aligned.
    length : int
        The length in bytes of the address range.
    debug : bool
        Turn on debug mode if it is True.
    array : numpy.ndarray
        A numpy view of the mapped range for efficient assignment

    """

    def __init__(self, base_addr, length=4, debug=False, device=None):
        """Return a new MMIO object.

        Parameters
        ----------
        base_addr : int
            The base address of the MMIO.
        length : int
            The length in bytes; default is 4.
        debug : bool
            Turn on debug mode if it is True; default is False.

        """
        if device is None:
            from .pl_server.device import Device
            device = Device.active_device
        self.device = device

        if base_addr < 0 or length < 0:
            raise ValueError("Base address or length cannot be negative.")

        self.base_addr = base_addr
        self.length = length
        self.debug = debug

        if self.device.has_capability('MEMORY_MAPPED'):
            self.read = self.read_mm
            self.write = self.write_mm
            self.array = self.device.mmap(base_addr, length)
        elif self.device.has_capability('REGISTER_RW'):
            self.read = self.read_reg
            self.write = self.write_reg
            self._hook = _AccessHook(self.base_addr, self.device)
            self.array = tnp.ndarray(shape=(length // 4,), dtype='u4',
                                    hook=self._hook)
        else:
            raise ValueError("Device does not have capabilities for MMIO")

        self._debug('MMIO(address, size) = ({0:x}, {1:x} bytes).',
                    self.base_addr, self.length)



    def read_mm(self, offset=0, length=4):
        """The method to read data from MMIO.

        Parameters
        ----------
        offset : int
            The read offset from the MMIO base address.
        length : int
            The length of the data in bytes.

        Returns
        -------
        list
            A list of data read out from MMIO

        """
        if length != 4:
            raise ValueError("MMIO currently only supports 4-byte reads.")
        if offset < 0:
            raise ValueError("Offset cannot be negative.")
        idx = offset >> 2
        if offset % 4:
            raise MemoryError('Unaligned read: offset must be multiple of 4.')

        self._debug('Reading {0} bytes from offset {1:x}',
                    length, offset)

        # Read data out
        return int(self.array[idx])

    def write_mm(self, offset, data):
        """The method to write data to MMIO.

        Parameters
        ----------
        offset : int
            The write offset from the MMIO base address.
        data : int / bytes
            The integer(s) to be written into MMIO.

        Returns
        -------
        None

        """
        if offset < 0:
            raise ValueError("Offset cannot be negative.")

        idx = offset >> 2
        if offset % 4:
            raise MemoryError('Unaligned write: offset must be multiple of 4.')

        if type(data) is int:
            self._debug('Writing 4 bytes to offset {0:x}: {1:x}',
                        offset, data)
            self.array[idx] = np.uint32(data)
        elif type(data) is bytes:
            length = len(data)
            num_words = length >> 2
            if length % 4:
                raise MemoryError(
                    'Unaligned write: data length must be multiple of 4.')
            buf = np.frombuffer(data, np.uint32, num_words, 0)
            for i in range(len(buf)):
                self.array[idx + i] = buf[i]
        else:
            raise ValueError("Data type must be int or bytes.")

    def read_reg(self, offset=0, length=4):
        """The method to read data from MMIO.

        Parameters
        ----------
        offset : int
            The read offset from the MMIO base address.
        length : int
            The length of the data in bytes.

        Returns
        -------
        list
            A list of data read out from MMIO

        """
        if length != 4:
            raise ValueError("MMIO currently only supports 4-byte reads.")
        if offset < 0:
            raise ValueError("Offset cannot be negative.")
        idx = offset >> 2
        if offset % 4:
            raise MemoryError('Unaligned read: offset must be multiple of 4.')

        self._debug('Reading {0} bytes from offset {1:x}',
                    length, offset)

        # Read data out
        return int(self.array[idx])

    def write_reg(self, offset, data):
        """The method to write data to MMIO.

        Parameters
        ----------
        offset : int
            The write offset from the MMIO base address.
        data : int / bytes
            The integer(s) to be written into MMIO.

        Returns
        -------
        None

        """
        if offset < 0:
            raise ValueError("Offset cannot be negative.")

        idx = offset >> 2
        if offset % 4:
            raise MemoryError('Unaligned write: offset must be multiple of 4.')

        if type(data) is int:
            self._debug('Writing 4 bytes to offset {0:x}: {1:x}',
                        offset, data)
            self.array[idx] = data
        elif type(data) is bytes:
            self._hook.write(offset, data)
        else:
            raise ValueError("Data type must be int or bytes.")
    def _debug(self, s, *args):
        """The method provides debug capabilities for this class.

        Parameters
        ----------
        s : str
            The debug information format string
        *args : any
            The arguments to be formatted

        Returns
        -------
        None

        """
        if self.debug:
            print('MMIO Debug: {}'.format(s.format(*args)))
