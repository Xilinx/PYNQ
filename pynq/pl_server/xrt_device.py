#   Copyright (c) 2019-2022, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import asyncio
import copy
import ctypes
import errno
import glob
import os
import subprocess
import warnings
import weakref

import numpy as np
from pynq._3rdparty import ert, xrt
from pynq.buffer import PynqBuffer
from pynq.ps import CPU_ARCH_IS_x86

from .device import Device



DRM_XOCL_BO_EXECBUF = 1 << 31
REQUIRED_VERSION_ERT = (2, 3, 0)
ZOCL_BO_FLAGS_CACHEABLE = 1 << 24
libc = ctypes.CDLL("libc.so.6")

libc.munmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
libc.munmap.restype = ctypes.c_int


# Create our own struct that fixes the typos of the real one
class xclDeviceUsage(ctypes.Structure):
    _fields_ = [
        ("h2c", ctypes.c_size_t * 8),
        ("c2h", ctypes.c_size_t * 8),
        ("ddrMemUsed", ctypes.c_size_t * 8),
        ("ddrBOAllocated", ctypes.c_uint * 8),
        ("totalContents", ctypes.c_uint),
        ("xclbinId", ctypes.c_ulonglong * 4),
        ("dma_channel_cnt", ctypes.c_uint),
        ("mm_channel_cnt", ctypes.c_uint),
        ("memSize", ctypes.c_ulonglong * 8),
    ]


_xrt_errors = {
    -95: "Shell does not match",
    -16: "Bitstream in use by another program",
    -1: "Possibly buffers still allocated",
}


def _get_xrt_version_embedded():
    output = subprocess.run(
        ["xbutil", "--version"], stdout=subprocess.PIPE, universal_newlines=True
    )
    if output.returncode != 0:
        warnings.warn("xbutil failed to run - unable to determine XRT version")
        return (0, 0, 0)
    xrt_version_str = output.stdout.split("\n")[0].split(":")[1].strip()
    return tuple(map(int, xrt_version_str.split(".")))


def _get_xrt_version_x86():
    import json

    try:
        with open(os.environ["XILINX_XRT"] + "/version.json", "r") as f:
            details = json.loads(f.read())
        return tuple(int(s) for s in details["BUILD_VERSION"].split("."))
    except Exception:
        warnings.warn("Unable to determine XRT version")
        return (0, 0, 0)


if xrt.XRT_SUPPORTED:
    _xrt_version = (
        _get_xrt_version_x86() if CPU_ARCH_IS_x86 else _get_xrt_version_embedded()
    )
else:
    _xrt_version = (0, 0, 0)


def _format_xrt_error(err):
    errstring = "{} ({}) {}".format(errno.errorcode[-err], -err, os.strerror(-err))
    if err in _xrt_errors:
        errstring += "/" + _xrt_errors[err]
    return errstring


def _xrt_allocate(shape, dtype, device, memidx, cacheable=0, pointer=None, cache=None):
    elements = 1
    try:
        for s in shape:
            elements *= s
    except TypeError:
        elements = shape
    dtype = np.dtype(dtype)
    size = elements * dtype.itemsize
    if pointer is not None:
        bo, buf, device_address = pointer
    else:
        bo = device.allocate_bo(size, memidx, cacheable)
        buf = device.map_bo(bo)
        device_address = device.get_device_address(bo)
    ar = PynqBuffer(
        shape,
        dtype,
        bo=bo,
        device=device,
        buffer=buf,
        device_address=device_address,
        coherent=False,
    )
    if pointer is not None:
        weakref.finalize(buf, _free_bo, device, bo, ar.virtual_address, ar.nbytes)
    if cache is not None:
        ar.pointer = (bo, buf, device_address)
        ar.return_to = cache
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
        self.idx = desc["idx"]
        self.size = desc["size"]
        self.base_address = desc["base_address"]
        self.desc = desc
        self.device = device

    def allocate(self, shape, dtype, **kwargs):
        """Create a new  buffer in the memory bank

        Parameters
        ----------
        shape : tuple(int)
            Shape of the array
        dtype : np.dtype
            Data type of the array

        """
        buf = _xrt_allocate(shape, dtype, self.device, self.idx, **kwargs)
        buf.memory = self
        return buf

    def __hash__(self):
        return hash((self.device, self.idx))

    def __eq__(self, other):
        return (
            type(other) is XrtMemory
            and self.device == other.device
            and self.idx == other.idx
        )

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
    """WaitHandle specific to ERT-scheduled accelerators"""

    def __init__(self, bo, future, device):
        self._future = future
        self._bo = bo
        self.device = device

    def _complete(self, state):
        if state != ert.ert_cmd_state.ERT_CMD_STATE_COMPLETED:
            self._future.set_exception(RuntimeError("Execution failed: " + str(state)))
        else:
            self._future.set_result(None)
        self._bo = None

    @property
    def _has_bo(self):
        return self._bo is not None

    @property
    def done(self):
        """True is the accelerator has finished"""
        return self._future.done()

    async def wait_async(self):
        """Coroutine to wait for the execution to be completed

        This function requires that ``XrtDevice.set_event_loop`` is called
        before the accelerator execution is started

        """
        await self._future

    def wait(self):
        """Wait for the Execution to be completed"""
        while not self.done:
            self.device._handle_events(1000)


class XrtStream:
    """XRT Streaming Connection

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
        idx = desc["idx"]
        for ip_name, ip in ip_dict.items():
            for stream_name, stream in ip["streams"].items():
                if stream["stream_id"] == idx:
                    if stream["direction"] == "output":
                        self.source = ip_name + "." + stream_name
                    elif stream["direction"] == "input":
                        self.sink = ip_name + "." + stream_name
        self.source_ip = None
        self.monitors = []
        self.monitor_ips = []
        self.sink_ip = None

    def __repr__(self):
        return "XrtStream(source={}, sink={})".format(self.source, self.sink)


class XrtDevice(Device):
    @classmethod
    def _probe_(cls):
        if not xrt.XRT_SUPPORTED or not CPU_ARCH_IS_x86:
            return []
        num = xrt.xclProbe()
        devices = [XrtDevice(i) for i in range(num)]
        return devices

    _probe_priority_ = 200

    def __init__(self, index, tag="xrt{}"):
        super().__init__(tag.format(index))
        self.capabilities = {
            "REGISTER_RW": True,
            "CALLABLE": True,
        }
        if _xrt_version >= REQUIRED_VERSION_ERT:
            self.capabilities["ERT"] = True
        self._index = index
        self._get_handle()
        self._info = xrt.xclDeviceInfo2()
        xrt.xclGetDeviceInfo2(self.handle, self._info)
        self.contexts = dict()
        self._find_sysfs()
        self.active_bos = []
        self._bo_cache = []
        self._loop = asyncio.get_event_loop()
        self._streams = {}

    def _get_handle(self):
        self.handle = xrt.xclOpen(self._index, None, 0)

    def _find_sysfs(self):
        devices = glob.glob("/sys/bus/pci/drivers/xclmgmt/*:*")
        self.sysfs_path = None
        for d in devices:
            with open(os.path.join(d, "slot")) as f:
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
    def clocks(self):
        """Runtime clocks. This dictionary provides the actual
        clock frequencies that the hardware is running at.
        Frequencies are expressed in Mega Hertz.
        """
        clks = {}
        idx = 0
        for clk in self._info.mOCLFrequency:
            if clk != 0:
                clks["clock" + str(idx)] = {"frequency": clk}
                idx += 1
        return clks

    @property
    def sensors(self):
        from pynq.pmbus import get_xrt_sysfs_rails

        return get_xrt_sysfs_rails(self)

    @property
    def default_memory(self):
        mem_dict = self.mem_dict
        active_mems = [m for m in mem_dict.values() if m["used"] and not m["streaming"]]
        if len(active_mems) == 0:
            raise RuntimeError("No active memories in design")
        elif len(active_mems) > 1:
            raise RuntimeError(
                "Multiple memories active in design: specify"
                + " the memory using the `target` parameters"
            )
        return self.get_memory(active_mems[0])

    def flush(self, bo, offset, ptr, size):
        ret = xrt.xclSyncBO(
            self.handle,
            bo,
            xrt.xclBOSyncDirection.XCL_BO_SYNC_BO_TO_DEVICE,
            size,
            offset,
        )
        if ret >= 0x80000000:
            raise RuntimeError("Flush Failed: " + str(ret))

    def invalidate(self, bo, offset, ptr, size):
        ret = xrt.xclSyncBO(
            self.handle,
            bo,
            xrt.xclBOSyncDirection.XCL_BO_SYNC_BO_FROM_DEVICE,
            size,
            offset,
        )
        if ret >= 0x80000000:
            raise RuntimeError("Invalidate Failed: " + str(ret))

    def allocate_bo(self, size, idx, cacheable):
        if cacheable:
            idx |= ZOCL_BO_FLAGS_CACHEABLE
        bo = xrt.xclAllocBO(self.handle, size, xrt.xclBOKind.XCL_BO_DEVICE_RAM, idx)
        if bo >= 0x80000000:
            raise RuntimeError("Allocate failed: " + str(bo))
        return bo

    def buffer_write(self, bo, bo_offset, buf, buf_offset=0, count=-1):
        view = memoryview(buf).cast("B")
        if count == -1:
            view = view[buf_offset:]
        else:
            view = view[buf_offset : buf_offset + count]
        ptr = (ctypes.c_char * len(view)).from_buffer(view)
        status = xrt.xclWriteBO(self.handle, bo, ptr, len(view), bo_offset)
        if status != 0:
            raise RuntimeError("Buffer Write Failed: " + str(status))

    def buffer_read(self, bo, bo_offset, buf, buf_offset=0, count=-1):
        view = memoryview(buf).cast("B")
        if view.readonly:
            raise RuntimeError("Buffer not writable")
        if count == -1:
            view = view[buf_offset:]
        else:
            view = view[buf_offset : buf_offset + count]
        ptr = (ctypes.c_char * len(view)).from_buffer(view)
        status = xrt.xclReadBO(self.handle, bo, ptr, len(view), bo_offset)
        if status != 0:
            raise RuntimeError("Buffer Write Failed: " + str(status))

    def map_bo(self, bo):
        ptr = xrt.xclMapBO(self.handle, bo, True)
        prop = xrt.xclBOProperties()
        if xrt.xclGetBOProperties(self.handle, bo, prop):
            raise RuntimeError("Failed to get buffer properties")
        size = prop.size
        casted = ctypes.cast(ptr, ctypes.POINTER(ctypes.c_char * size))
        return casted[0]

    def get_device_address(self, bo):
        prop = xrt.xclBOProperties()
        xrt.xclGetBOProperties(self.handle, bo, prop)
        return prop.paddr

    def get_usage(self):
        usage = xclDeviceUsage()
        status = xrt.xclGetUsageInfo(
            self.handle,
            ctypes.cast(ctypes.pointer(usage), ctypes.POINTER(xrt.xclDeviceInfo2)),
        )
        if status != 0:
            raise RuntimeError("Get Usage Failed: " + str(status))
        return usage

    def close(self):
        if self.handle:
            xrt.xclClose(self.handle)
        self.handle = None

    def get_memory(self, desc):
        if desc["streaming"]:
            if desc["idx"] not in self._streams:
                self._streams[desc["idx"]] = XrtStream(self, desc)
            return self._streams[desc["idx"]]
        else:
            return XrtMemory(self, desc)

    def get_memory_by_idx(self, idx):
        for m in self.mem_dict.values():
            if m["idx"] == idx:
                return self.get_memory(m)
        raise RuntimeError("Could not find memory")

    def get_memory_by_name(self, name):
        for m in self.mem_dict.values():
            if m["tag"] == name:
                return self.get_memory(m)
        raise RuntimeError("Could not find memory")

    def read_registers(self, address, length):
        data = (ctypes.c_char * length)()
        ret = xrt.xclRead(
            self.handle, xrt.xclAddressSpace.XCL_ADDR_KERNEL_CTRL, address, data, length
        )
        return bytes(data)

    def write_registers(self, address, data):
        cdata = (ctypes.c_char * len(data)).from_buffer_copy(data)
        xrt.xclWrite(
            self.handle,
            xrt.xclAddressSpace.XCL_ADDR_KERNEL_CTRL,
            address,
            cdata,
            len(data),
        )

    def free_bitstream(self):
        for k, v in self.contexts.items():
            xrt.xclCloseContext(self.handle, v["uuid_ctypes"], v["idx"])
        self.contexts = dict()

    def _xrt_download(self, data):
        # Keep copy of old contexts so we can reacquire them if
        # downloading fails
        old_contexts = copy.deepcopy(self.contexts)
        # Close existing contexts
        for k, v in self.contexts.items():
            xrt.xclCloseContext(self.handle, v["uuid_ctypes"], v["idx"])
        self.contexts = dict()

        # Download xclbin file
        if not self.handle:
            self._get_handle()
        err = xrt.xclLockDevice(self.handle)
        if err:
            raise RuntimeError("Could not lock device for programming - " + str(err))
        try:
            err = xrt.xclLoadXclBin(self.handle, data)
            if err:
                for k, v in old_contexts:
                    xrt.xclOpenContext(self.handle, v["uuid_ctypes"], v["idx"], True)
                self.contexts = old_contexts
                raise RuntimeError(
                    "Programming Device failed: " + _format_xrt_error(err)
                )
        finally:
            xrt.xclUnlockDevice(self.handle)

    def gen_cache(self, bitstream, parser=None):
        pass

    def download(self, bitstream, parser=None):
        with open(bitstream.bitfile_name, "rb") as f:
            data = f.read()
        self._xrt_download(data)
        super().post_download(bitstream, parser)

    def open_context(self, description, shared=True):
        """Open XRT context for the compute unit"""

        cu_name = description["cu_name"]
        context = self.contexts.get(cu_name)
        if context:
            return context["idx"]
        if _xrt_version >= (2, 6, 0):
            cu_index = xrt.xclIPName2Index(self.handle, cu_name)
            description["cu_index"] = cu_index
        else:
            cu_index = description["cu_index"]

        uuid = bytes.fromhex(description["xclbin_uuid"])
        uuid_ctypes = XrtUUID((ctypes.c_char * 16).from_buffer_copy(uuid))
        err = xrt.xclOpenContext(self.handle, uuid_ctypes, cu_index, shared)

        if err:
            raise RuntimeError(
                "Could not open CU context - {}, {}".format(err, cu_index)
            )
        # Setup the execution context for the compute unit
        self.contexts[cu_name] = {
            "cu": cu_name,
            "idx": cu_index,
            "uuid_ctypes": uuid_ctypes,
            "shared": shared,
        }

        return cu_index

    def close_context(self, cu_name):
        """Close XRT context for the compute unit"""

        context = self.contexts.get(cu_name)
        if context is None:
            raise RuntimeError("CU context ({}) is not open.".format(cu_name))
        xrt.xclCloseContext(self.handle, context["uuid_ctypes"], context["idx"])
        self.contexts.pop(cu_name)

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
            raise RuntimeError("Buffer submit failed: " + str(status))
        wh = ErtWaitHandle(bo, self._loop.create_future(), self)
        self.active_bos.append((bo, wh))
        return wh

    def execute_bo_with_waitlist(self, bo, waitlist):
        if _xrt_version >= (2, 11, 0):
            raise RuntimeError(
                "waitfor list to schedule dependent executions "
                "is not supported by XRT anymore."
            )
        wait_array = (ctypes.c_uint * len(waitlist))()
        for i in range(len(waitlist)):
            wait_array[i] = waitlist[i].bo
        status = xrt.xclExecBufWithWaitList(
            self.handle, bo.bo, len(waitlist), wait_array
        )
        if status:
            raise RuntimeError("Buffer submit failed: " + str(status))
        wh = ErtWaitHandle(bo, self._loop.create_future(), self)
        self.active_bos.append((bo, wh))
        return wh

    def set_event_loop(self, loop):
        self._loop = loop
        for fd in glob.glob("/proc/self/fd/*"):
            try:
                link_target = os.readlink(fd)
            except:
                continue
            if link_target.startswith("/dev/dri/renderD"):
                base_fd = int(os.path.basename(fd))
                loop.add_reader(open(base_fd, closefd=False), self._handle_events)

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


