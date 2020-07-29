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

import asyncio
import copy
import ctypes
import errno
import glob
import os
import warnings
import weakref
import numpy as np
from pynq.buffer import PynqBuffer
from .device import Device

try:
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", category=SyntaxWarning)
        import xrt_binding as xrt
        import ert_binding as ert
except ImportError:
    from pynq import xrt
    from pynq import ert

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"


if "XCL_EMULATION_MODE" in os.environ:
    emulation_mode = os.environ["XCL_EMULATION_MODE"]
    if emulation_mode == "hw_emu":
        xrt_lib = os.path.join(
            os.environ['XILINX_XRT'], 'lib', 'libxrt_hwemu.so')
    elif emulation_mode == "sw_emu":
        raise RuntimeError("PYNQ doesn't support software emulation: either "
                           "unset XCL_EMULATION_MODE or set it hw_emu")
    else:
        warnings.warn("Unknown emulation mode: " + emulation_mode)
        xrt_lib = os.path.join(
            os.environ['XILINX_XRT'], 'lib', 'libxrt_core.so')
    xrt.libc = ctypes.CDLL(xrt_lib)

DRM_XOCL_BO_EXECBUF = 1 << 31
REQUIRED_VERSION_ERT = (2, 3, 0)
libc = ctypes.CDLL('libc.so.6')
libc.munmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
libc.munmap.restype = ctypes.c_int


# Create our own struct that fixes the typos of the real one
class xclDeviceUsage (ctypes.Structure):
    _fields_ = [
        ("h2c", ctypes.c_size_t*8),
        ("c2h", ctypes.c_size_t*8),
        ("ddrMemUsed", ctypes.c_size_t*8),
        ("ddrBOAllocated", ctypes.c_uint*8),
        ("totalContents", ctypes.c_uint),
        ("xclbinId", ctypes.c_ulonglong*4),
        ("dma_channel_cnt", ctypes.c_uint),
        ("mm_channel_cnt", ctypes.c_uint),
        ("memSize", ctypes.c_ulonglong*8)
    ]

_xrt_errors = {
    -95: "Shell does not match",
    -16: "Bitstream in use by another program",
    -1: "Possibly buffers still allocated"
}


def _get_xrt_version():
    import subprocess
    import json
    try:
        output = subprocess.run(['xbutil', 'dump'], stdout=subprocess.PIPE,
                                universal_newlines=True)
        details = json.loads(output.stdout)
        return tuple(
            int(s) for s in details['runtime']['build']['version'].split('.'))
    except Exception:
        return (0, 0, 0)


_xrt_version = _get_xrt_version()


def _format_xrt_error(err):
    errstring = "{} ({}) {}".format(errno.errorcode[-err],
                                    -err, os.strerror(-err))
    if err in _xrt_errors:
        errstring += "/" + _xrt_errors[err]
    return errstring


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
    ar = PynqBuffer(shape, dtype, bo=bo, device=device, buffer=buf,
                    device_address=device_address, coherent=False)
    weakref.finalize(buf, _free_bo, device, bo, ar.virtual_address, ar.nbytes)
    return ar


def _free_bo(device, bo, ptr, length):
    libc.munmap(ctypes.cast(ptr, ctypes.c_void_p), length)
    xrt.xclFreeBO(device.handle, bo)


class XrtMemory:
    """Class representing a memory bank in a card

    Memory banks can be both external DDR banks and internal buffers.
    XrtMemory instances for the same bank are interchangeable and can
    be compared and used as dictionary keys.

    """
    def __init__(self, device, desc):
        self.idx = desc['idx']
        self.size = desc['size']
        self.desc = desc
        self.device = device

    def allocate(self, shape, dtype):
        """Create a new  buffer in the memory bank

        Parameters
        ----------
        shape : tuple(int)
            Shape of the array
        dtype : np.dtype
            Data type of the array

        """
        buf = _xrt_allocate(shape, dtype, self.device, self.idx)
        buf.memory = self
        return buf

    def __hash__(self):
        return hash((self.device, self.idx))

    def __eq__(self, other):
        return (type(other) is XrtMemory and
                self.device == other.device and
                self.idx == other.idx)

    @property
    def mem_used(self):
        usage = self.device.get_usage()
        return usage.ddrMemUsed[self.idx]

    @property
    def num_buffers(self):
        usage = self.device.get_usage()
        return usage.ddrBOAllocated[self.idx]


class XrtUUID:
    def __init__(self, val):
        self.bytes = val


class ExecBo:
    """Execution Buffer Object

    Wraps an execution buffer used by XRT to schedule the execution of
    accelerators. Usually used in conjunction with the ERT packet format
    exposed in the XRT ``ert_binding`` python module.

    """
    def __init__(self, bo, ptr, device, length):
        self.bo = bo
        self.ptr = ptr
        self.device = device
        self.length = length

    def __del__(self):
        _free_bo(self.device, self.bo, self.ptr, self.length)

    def as_packet(self, ptype):
        """Get a packet representation of the buffer object

        Parameters
        ----------
        ptype : ctypes struct
            The type to cast the buffer to

        """
        return ctypes.cast(self.ptr, ctypes.POINTER(ptype))[0]


class ErtWaitHandle:
    """WaitHandle specific to ERT-scheduled accelerators

    """
    def __init__(self, bo, future, device):
        self._future = future
        self._bo = bo
        self.device = device

    def _complete(self, state):
        if state != ert.ert_cmd_state.ERT_CMD_STATE_COMPLETED:
            self._future.set_exception(RuntimeError("Execution failed: " +
                                                    str(state)))
        else:
            self._future.set_result(None)
        self._bo = None

    @property
    def _has_bo(self):
        return self._bo is not None

    @property
    def done(self):
        """True is the accelerator has finished

        """
        return self._future.done()

    async def wait_async(self):
        """Coroutine to wait for the execution to be completed

        This function requires that ``XrtDevice.set_event_loop`` is called
        before the accelerator execution is started

        """
        await self._future

    def wait(self):
        """Wait for the Execution to be completed

        """
        while not self.done:
            self.device._handle_events(1000)


class XrtStream:
    """XRT Streming Connection

    Encapsulates the IP connected to a stream. Note that the ``_ip``
    attributes will only be populated if the corresponding device
    driver has been instantiated.

    Attributes
    ----------
    source : str
        Source of the streaming connection as ip_name.port
    sink : str
        Sink of the streaming connection as ip_name.port
    monitors : [str]
        Monitor connections of the stream as a list of ip_name.port
    source_ip : pynq.overlay.DefaultIP
        Source IP driver instance for the stream
    sink_ip : pynq.overlay.DefaultIP
        Sink IP driver instance for the stream
    monitor_ips : [pynq.overlay.DefaultIP]
        list of driver instances for IP monitoring the stream

    """
    def __init__(self, device, desc):
        ip_dict = device.ip_dict
        idx = desc['idx']
        for ip_name, ip in ip_dict.items():
            for stream_name, stream in ip['streams'].items():
                if stream['stream_id'] == idx:
                    if stream['direction'] == 'output':
                        self.source = ip_name + "." + stream_name
                    elif stream['direction'] == 'input':
                        self.sink = ip_name + "." + stream_name
        self.source_ip = None
        self.monitors = []
        self.monitor_ips = []
        self.sink_ip = None

    def __repr__(self):
        return 'XrtStream(source={}, sink={})'.format(self.source,
                                                      self.sink)


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
            'REGISTER_RW': True,
            'CALLABLE': True,
        }
        if _xrt_version >= REQUIRED_VERSION_ERT:
            self.capabilities['ERT'] = True
        self.handle = xrt.xclOpen(index, None, 0)
        self._info = xrt.xclDeviceInfo2()
        xrt.xclGetDeviceInfo2(self.handle, self._info)
        self.contexts = []
        self._find_sysfs()
        self.active_bos = []
        self._bo_cache = []
        self._loop = asyncio.get_event_loop()
        self._streams = {}

    def _find_sysfs(self):
        devices = glob.glob('/sys/bus/pci/drivers/xclmgmt/*:*')
        self.sysfs_path = None
        for d in devices:
            with open(os.path.join(d, 'slot')) as f:
                slot = int(f.read())
            if slot == self._info.mPciSlot:
                self.sysfs_path = os.path.realpath(d)


    @property
    def device_info(self):
        info = xrt.xclDeviceInfo2()
        xrt.xclGetDeviceInfo2(self.handle, info)
        return info

    @property
    def name(self):
        return self._info.mName.decode()

    @property
    def sensors(self):
        from pynq.pmbus import get_xrt_sysfs_rails
        return get_xrt_sysfs_rails(self)

    @property
    def default_memory(self):
        mem_dict = self.mem_dict
        active_mems = [m for m in mem_dict.values()
                       if m['used'] and not m['streaming']]
        if len(active_mems) == 0:
            raise RuntimeError("No active memories in design")
        elif len(active_mems) > 1:
            raise RuntimeError("Multiple memories active in design: specify" +
                               " the memory using the `target` parameters")
        return self.get_memory(active_mems[0])

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

    def buffer_write(self, bo, bo_offset, buf, buf_offset=0, count=-1):
        view = memoryview(buf).cast('B')
        if count == -1:
            view = view[buf_offset:]
        else:
            view = view[buf_offset:buf_offset+count]
        ptr = (ctypes.c_char * len(view)).from_buffer(view)
        status = xrt.xclWriteBO(self.handle, bo, ptr, len(view), bo_offset)
        if status != 0:
            raise RuntimeError("Buffer Write Failed: " + str(status))

    def buffer_read(self, bo, bo_offset, buf, buf_offset=0, count=-1):
        view = memoryview(buf).cast('B')
        if view.readonly:
            raise RuntimeError("Buffer not writable")
        if count == -1:
            view = view[buf_offset:]
        else:
            view = view[buf_offset:buf_offset+count]
        ptr = (ctypes.c_char * len(view)).from_buffer(view)
        status = xrt.xclReadBO(self.handle, bo, ptr, len(view), bo_offset)
        if status != 0:
            raise RuntimeError("Buffer Write Failed: " + str(status))

    def map_bo(self, bo):
        ptr = xrt.xclMapBO(self.handle, bo, True)
        prop = xrt.xclBOProperties()
        if xrt.xclGetBOProperties(self.handle, bo, prop):
            raise RuntimeError('Failed to get buffer properties')
        size = prop.size
        casted = ctypes.cast(ptr, ctypes.POINTER(ctypes.c_char * size))
        return casted[0]

    def get_device_address(self, bo):
        prop = xrt.xclBOProperties()
        xrt.xclGetBOProperties(self.handle, bo, prop)
        return prop.paddr

    def get_usage(self):
        usage = xclDeviceUsage()
        status = xrt.xclGetUsageInfo(self.handle, ctypes.cast(
            ctypes.pointer(usage),
            ctypes.POINTER(xrt.xclDeviceInfo2)))
        if status != 0:
            raise RuntimeError("Get Usage Failed: " + str(status))
        return usage

    def close(self):
        if self.handle:
            xrt.xclClose(self.handle)
        self.handle = None
        super().close()

    def get_memory(self, desc):
        if desc['streaming']:
            if desc['idx'] not in self._streams:
                self._streams[desc['idx']] = XrtStream(self, desc)
            return self._streams[desc['idx']]
        else:
            return XrtMemory(self, desc)

    def get_memory_by_idx(self, idx):
        for m in self.mem_dict.values():
            if m['idx'] == idx:
                return self.get_memory(m)
        raise RuntimeError("Could not find memory")

    def read_registers(self, address, length):
        data = (ctypes.c_char * length)()
        ret = xrt.xclRead(self.handle,
                          xrt.xclAddressSpace.XCL_ADDR_KERNEL_CTRL,
                          address, data, length)
        return bytes(data)

    def write_registers(self, address, data):
        cdata = (ctypes.c_char * len(data)).from_buffer_copy(data)
        xrt.xclWrite(self.handle, xrt.xclAddressSpace.XCL_ADDR_KERNEL_CTRL,
                     address, cdata, len(data))

    def free_bitstream(self):
        for c in self.contexts:
            xrt.xclCloseContext(self.handle, c[0], c[1])
        self.contexts = []

    def download(self, bitstream, parser=None):
        # Keep copy of old contexts so we can reacquire them if
        # downloading fails
        old_contexts = copy.deepcopy(self.contexts)
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
                for c in old_contexts:
                    xrt.xclOpenContext(self.handle, c[0], c[1], True)
                self.contexts = old_contexts
                raise RuntimeError("Programming Device failed: " +
                                   _format_xrt_error(err))
        finally:
            xrt.xclUnlockDevice(self.handle)

        super().post_download(bitstream, parser)

        # Setup the execution context for the new xclbin
        if parser is not None:
            ip_dict = parser.ip_dict
            cu_used = 0
            uuid = None
            for k, v in ip_dict.items():
                if 'index' in v:
                    index = v['adjusted_index']
                    uuid = bytes.fromhex(v['xclbin_uuid'])
                    uuid_ctypes = \
                        XrtUUID((ctypes.c_char * 16).from_buffer_copy(uuid))
                    err = xrt.xclOpenContext(self.handle, uuid_ctypes, index,
                                             True)
                    if err:
                        raise RuntimeError('Could not open CU context - {}, '
                                           '{}'.format(err, index))
                    self.contexts.append((uuid_ctypes, index))

    def get_bitfile_metadata(self, bitfile_name):
        from .xclbin_parser import XclBin
        return XclBin(bitfile_name)

    def get_exec_bo(self, size=1024):
        if len(self._bo_cache):
            return self._bo_cache.pop()
        if _xrt_version < REQUIRED_VERSION_ERT:
            raise RuntimeError("XRT Version too old for PYNQ ERT support")
        new_bo = xrt.xclAllocBO(self.handle, size, 0, DRM_XOCL_BO_EXECBUF)
        new_ptr = xrt.xclMapBO(self.handle, new_bo, 1)
        return ExecBo(new_bo, new_ptr, self, size)

    def return_exec_bo(self, bo):
        self._bo_cache.append(bo)

    def execute_bo(self, bo):
        status = xrt.xclExecBuf(self.handle, bo.bo)
        if status:
            raise RuntimeError('Buffer submit failed: ' + str(status))
        wh = ErtWaitHandle(bo, self._loop.create_future(), self)
        self.active_bos.append((bo, wh))
        return wh

    def execute_bo_with_waitlist(self, bo, waitlist):
        wait_array = (ctypes.c_uint * len(waitlist))()
        for i in range(len(waitlist)):
            wait_array[i] = waitlist[i].bo
        status = xrt.xclExecBufWithWaitList(
            self.handle, bo.bo, len(waitlist), wait_array)
        if status:
            raise RuntimeError('Buffer submit failed: ' + str(status))
        wh = ErtWaitHandle(bo, self._loop.create_future(), self)
        self.active_bos.append((bo, wh))
        return wh

    def set_event_loop(self, loop):
        self._loop = loop
        for fd in glob.glob('/proc/self/fd/*'):
            try:
                link_target = os.readlink(fd)
            except:
                continue
            if link_target.startswith('/dev/dri/renderD'):
                base_fd = int(os.path.basename(fd))
                loop.add_reader(open(base_fd, closefd=False),
                                self._handle_events)

    def _handle_events(self, timeout=0):
        xrt.xclExecWait(self.handle, timeout)
        next_bos = []
        for bo, completion in self.active_bos:
            state = bo.as_packet(ert.ert_cmd_struct).state & 0xF
            if state >= ert.ert_cmd_state.ERT_CMD_STATE_COMPLETED:
                if completion:
                    completion._complete(state)
                self.return_exec_bo(bo)
            else:
                next_bos.append((bo, completion))
        self.active_bos = next_bos
