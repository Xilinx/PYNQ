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

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"

import numpy as np


class PynqBuffer(np.ndarray):
    """A subclass of numpy.ndarray which is allocated using
    physically contiguous memory for use with DMA engines and
    hardware accelerators. As physically contiguous memory is a
    limited resource it is strongly recommended to free the
    underlying buffer with `close` when the buffer is no longer
    needed. Alternatively a `with` statement can be used to
    automatically free the memory at the end of the scope.

    This class should not be constructed directly and instead
    created using `pynq.allocate()`.

    Attributes
    ----------
    device_address: int
        The physical address to the array
    coherent: bool
        Whether the buffer is coherent

    """
    def __new__(cls, *args, device=None, device_address=0,
                bo=0, coherent=False, **kwargs):
        self = super().__new__(cls, *args, **kwargs)
        self.device_address = device_address
        self.coherent = coherent
        self.bo = bo
        self.device = device
        self.offset = 0
        return self

    def __array_finalize__(self, obj):
        if isinstance(obj, PynqBuffer) and obj.coherent is not None:
            self.coherent = obj.coherent
            offset = self.virtual_address - obj.virtual_address
            self.device_address = obj.device_address + offset
            self.offset = obj.offset + offset
            self.device = obj.device
            self.bo = obj.bo
        else:
            self.device_address = None
            self.coherent = None

    def __del__(self):
        self.freebuffer()

    def freebuffer(self):
        """Free the underlying memory

        This will free the memory regardless of whether other objects
        may still be using the buffer so ensure that no other references
        to the array exist prior to freeing.

        """
        if hasattr(self, 'pointer') and self.pointer:
            if self.return_to:
                self.return_to.return_pointer(self.pointer)
            self.pointer = 0

    @property
    def cacheable(self):
        return not self.coherent

    @property
    def physical_address(self):
        return self.device_address

    @property
    def virtual_address(self):
        return self.__array_interface__['data'][0]

    def close(self):
        """Unused - for backwards compatibility only

        """
        pass

    def flush(self):
        """Flush the underlying memory if necessary

        """
        if not self.coherent:
            self.device.flush(self.bo, self.offset,
                              self.virtual_address, self.nbytes)

    def invalidate(self):
        """Invalidate the underlying memory if necessary

        """
        if not self.coherent:
            self.device.invalidate(self.bo, self.offset,
                                   self.virtual_address, self.nbytes)

    def sync_to_device(self):
        """Copy the contents of the host buffer into the mirrored
        device buffer

        """
        self.flush()

    def sync_from_device(self):
        """Copy the contents of the device buffer into the mirrored
        host buffer

        """
        self.invalidate()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.free_buffer()
        return 0


def allocate(shape, dtype='u4', target=None, **kwargs):
    """Allocate a PYNQ buffer

    This API mimics the numpy ndarray constructor with the following
    differences:

     * The default dtype is 32-bit unsigned int rather than float
     * A new ``target`` keyword parameter to determine where the
       buffer should be allocated

    The target determines where the buffer gets allocated

     * If None then the currently active device is used
     * If a Device is specified then the main memory

    """
    from .pl_server import Device
    if target is None:
        target = Device.active_device
    return target.allocate(shape, dtype, **kwargs)
