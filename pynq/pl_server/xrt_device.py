#   Copyright (c) 2019, Xilinx, Inc.
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

import ctypes
import glob
import os
import numpy as np
from pynq.buffer import PynqBuffer
from .device import Device

try:
    import xrt_binding as xrt
except ImportError:
    from pynq import xrt


__author__ = "Peter Ogden"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _xrt_allocate(shape, dtype, device, memidx):
    elements = 1
    try:
        for s in shape:
            elements *= s
    except TypeError:
        elements = shape
    dtype = np.dtype(dtype)
    size = elements * dtype.itemsize
    bo = device.allocate_bo(size, memidx)
    buf = device.map_bo(bo)
    device_address = device.get_device_address(bo)
    return PynqBuffer(shape, dtype, bo=bo, device=device, buffer=buf,
                     device_address=device_address, coherent=False)
    

class XrtMemory:
    def __init__(self, device, desc):
        self.idx = desc['idx']
        self.size = desc['size']
        self.desc = desc 
        self.device = device

    def allocate(self, shape, dtype):
        return _xrt_allocate(shape, dtype, self.device, self.idx)


class XrtUUID:
    def __init__(self, val):
       self.bytes = val


class XrtDevice(Device):
    @classmethod
    def _probe_(cls):
        num = xrt.xclProbe()
        devices = [XrtDevice(i) for i in range(num)]
        return devices

    _probe_priority_ = 200
    
    def __init__(self, index):
        super().__init__('xrt{}'.format(index))
        self.capabilities = {
            'REGISTER_RW' : True,
            'CALLABLE' : True
        }
        self.handle = xrt.xclOpen(index, None, 0)
        self._info = xrt.xclDeviceInfo2()
        xrt.xclGetDeviceInfo2(self.handle, self._info)
        self.contexts = []
        self._find_sysfs()

    def _find_sysfs(self):
        devices = glob.glob('/sys/bus/pci/drivers/xclmgmt/*:*')
        self.sysfs_path = None
        for d in devices:
            with open(os.path.join(d, 'slot')) as f:
                slot = int(f.read())
            if slot == self._info.mPciSlot:
                self.sysfs_path = os.path.realpath(d)

    @property
    def name(self):
        return self._info.mName.decode()

    def flush(self, bo, offset, ptr, size):
        ret = xrt.xclSyncBO(
            self.handle, bo, xrt.xclBOSyncDirection.XCL_BO_SYNC_BO_TO_DEVICE,
            size, offset)
        if ret >= 0x80000000:
            raise RuntimeError("Flush Failed: " + str(ret))

    def invalidate(self, bo, offset, ptr, size):
        ret = xrt.xclSyncBO(
            self.handle, bo, xrt.xclBOSyncDirection.XCL_BO_SYNC_BO_FROM_DEVICE,
            size, offset)
        if ret >= 0x80000000:
            raise RuntimeError("Invalidate Failed: " + str(ret))

    def allocate_bo(self, size, idx):
        bo = xrt.xclAllocBO(self.handle, size, 
                            xrt.xclBOKind.XCL_BO_DEVICE_RAM, idx)
        if bo >= 0x80000000:
             raise RuntimeError("Allocate failed: " + str(bo))
        return bo

    def map_bo(self, bo):
        return xrt.xclMapBO(self.handle, bo, True)[0]

    def get_device_address(self, bo):
        prop = xrt.xclBOProperties()
        xrt.xclGetBOProperties(self.handle, bo, prop)
        return prop.paddr

    def close(self):
        if self.handle:
            xrt.xclClose(self.handle)
        self.handle = None
        super().close()

    def get_memory(self, desc):
        return XrtMemory(self, desc)

    def read_registers(self, address, length):
        data = (ctypes.c_char * length)()
        ret = xrt.xclRead(self.handle, xrt.xclAddressSpace.XCL_ADDR_KERNEL_CTRL,
                    address, data, length)
        return bytes(data)

    def write_registers(self, address, data):
        cdata = (ctypes.c_char * len(data)).from_buffer_copy(data)
        xrt.xclWrite(self.handle, xrt.xclAddressSpace.XCL_ADDR_KERNEL_CTRL,
                     address, cdata, len(data)) 

    def download(self, bitstream, parser=None):
        # Close existing contexts
        for c in self.contexts:
            xrt.xclCloseContext(self.handle, c[0], c[1])
        self.contexts = []

        # Download xclbin file
        err = xrt.xclLockDevice(self.handle)
        if err:
            raise RuntimeError(
                   "Could not lock device for programming - " + str(err))
        try:
            with open(bitstream.bitfile_name, 'rb') as f:
                data = f.read()
            err = xrt.xclLoadXclBin(self.handle, data)
            if err:
                raise RuntimeError("Programming Device failed - " + str(err))
        finally:
            xrt.xclUnlockDevice(self.handle)

        super().post_download(bitstream, parser)

        # Setup the execution context for the new xclbin
        if parser is not None:
            ip_dict = parser.ip_dict
            cu_used = 0
            addresses = {}
            uuid = None
            for k, v in ip_dict.items():
                if 'index' in v:
                    index = v['index']
                    cu_used |= 1 << index
                    addresses[index] = v['phys_addr']
                    uuid = bytes.fromhex(v['xclbin_uuid'])
            uuid_ctypes = XrtUUID((ctypes.c_char * 16).from_buffer_copy(uuid))
            err = xrt.xclOpenContext(self.handle, uuid_ctypes, cu_used, True)
            if err:
                raise RuntimeError('Could not open CU context - ' + str(err))
            self.contexts.append((uuid_ctypes, cu_used))

    def get_bitfile_metadata(self, bitfile_name):
        from .xclbin_parser import XclBin
        return XclBin(bitfile_name)
