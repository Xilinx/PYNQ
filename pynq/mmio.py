#   Copyright (c) 2022, Xilinx, Inc.
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

import numpy as np
import pynq._3rdparty.tinynumpy as tnp
import struct
import warnings

__author__ = "Yun Rock Qu, Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
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
    array : numpy.ndarray
        A numpy view of the mapped range for efficient assignment
    device : Device
        A device that can interact with the PL server.

    """

    def __init__(self, base_addr, length=4, device=None, **kwargs):
        """Return a new MMIO object.

        Parameters
        ----------
        base_addr : int
            The base address of the MMIO.
        length : int
            The length in bytes; default is 4.
        device: Device
            The device that MMIO object is created for.

        """
        if 'debug' in kwargs:
            warnings.warn("Keyword debug has been deprecated.",
                          DeprecationWarning)

        if device is None:
            from .pl_server.device import Device
            device = Device.active_device
        self.device = device

        if base_addr < 0 or length < 0:
            raise ValueError("Base address or length cannot be negative.")

        self.base_addr = base_addr
        self.length = length

        if self.device.has_capability('MEMORY_MAPPED'):
            self.array = self.device.mmap(base_addr, length)
        elif self.device.has_capability('REGISTER_RW'):
            self._hook = _AccessHook(self.base_addr, self.device)
            self.array = tnp.ndarray(shape=(length // 4,), dtype='u4',
                                     hook=self._hook)
        else:
            raise ValueError("Device does not have capabilities for MMIO")

    def read(self, offset=0, **kwargs):
        """The method to read data from MMIO.

        Parameters
        ----------
        offset : int
            The read offset from the MMIO base address.

        Returns
        -------
        list
            A list of data read out from MMIO

        """

        if 'length' in kwargs:
            warnings.warn("Keyword length has been deprecated.",
                          DeprecationWarning)
        if 'word_order' in kwargs:
            warnings.warn("Keyword word_order has been deprecated.",
                          DeprecationWarning)

        if offset < 0:
            raise ValueError("Offset cannot be negative.")
        elif offset % 4:
            raise MemoryError('Unaligned read: offset must be multiple of 4.')
        idx = offset >> 2

        dtype = kwargs.get('dtype')
        lsb = int(self.array[idx])
        if dtype in [np.int8, np.uint8, np.int16, np.uint16, np.uint32,
                     np.int32, int]:
            lsb = dtype(lsb)
        elif dtype in [np.int64, np.uint64]:
            msb = np.uint64(np.uint64(self.array[idx + 1]) * 2**32)
            lsb = dtype(msb + np.uint64(lsb))
        elif dtype in [np.float32, float]:
            lsb = dtype(struct.unpack('!f', lsb.to_bytes(4, 'big'))[0])
        elif dtype:
            raise ValueError("dtype \'{}\' is not supported".format(dtype))

        return lsb

    def write(self, offset, data):
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
        elif offset % 4:
            raise MemoryError('Unaligned write: offset must be multiple of 4.')
        idx = offset >> 2

        dtype = type(data)
        if dtype == int:
            data = data.to_bytes(4, 'little', signed=True)
        elif dtype in [np.uint32, np.int32, int, np.int64, np.uint64]:
            data = data.tobytes()
        elif dtype in [np.int8, np.uint8, np.int16, np.uint16]:
            data = np.int32(data).tobytes()
        elif dtype in [np.float32, float]:
            data = struct.pack('f', np.float32(data))
        elif dtype is not bytes:
            raise ValueError("dtype \'{}\' is not supported".format(dtype))

        if self.device.has_capability('REGISTER_RW'):
            self._hook.write(offset, data)
        else:
            length = len(data)
            num_words = length >> 2
            if length % 4:
                raise MemoryError(
                    'Unaligned write: data length must be multiple of 4.')
            buf = np.frombuffer(data, np.uint32, num_words, 0)
            for i in range(len(buf)):
                self.array[idx + i] = buf[i]
