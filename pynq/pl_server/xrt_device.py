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
from collections import namedtuple
from pynq.buffer import PynqBuffer
from pynq.ps import ON_TARGET

if ON_TARGET:
    import pyxrt
    libc = ctypes.CDLL("libc.so.6")
    libc.munmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
    libc.munmap.restype = ctypes.c_int

from .device import Device

DRM_XOCL_BO_EXECBUF = 1 << 31
ZOCL_BO_FLAGS_CACHEABLE = 1 << 24


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
    del bo
    


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
    accelerators. 

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
        # XrtDevice has been deprecated. This probe will now always return an empty list.
        return []

    _probe_priority_ = 200

    def __init__(self, index, tag="xrt{}"):
        super().__init__(tag.format(index))
        self.capabilities = {
            "REGISTER_RW": True,
            "CALLABLE": True,
        }
        self._index = index
        self._get_handle()
        self._info = self.device_info
        self.contexts = dict()
        self._find_sysfs()
        self.active_bos = []
        self._bo_cache = []
        self._loop = asyncio.get_event_loop()
        self._streams = {}

    def _get_handle(self):
        self.handle = pyxrt.device(self._index)

    def _find_sysfs(self):
        devices = glob.glob("/sys/bus/pci/drivers/xclmgmt/*:*")
        self.sysfs_path = None
        for d in devices:
            with open(os.path.join(d, "slot")) as f:
                slot = int(f.read())
            if slot == self._info.pcie_info:
                self.sysfs_path = os.path.realpath(d)

    @property
    def device_info(self):
        DeviceInfo = namedtuple('DeviceInfo', [
            'bdf', 'dynamic_regions', 'electrical', 'host', 'm2m', 'max_clock_frequency_mhz',
            'mechanical', 'memory', 'name', 
            'pcie_info', 'thermal', 'vmr'
        ])
        info = DeviceInfo(
            bdf=self.handle.get_info(pyxrt.xrt_info_device.bdf),
            dynamic_regions=self.handle.get_info(pyxrt.xrt_info_device.dynamic_regions),
            electrical=self.handle.get_info(pyxrt.xrt_info_device.electrical),
            host=self.handle.get_info(pyxrt.xrt_info_device.host),
            m2m=self.handle.get_info(pyxrt.xrt_info_device.m2m),
            max_clock_frequency_mhz=self.handle.get_info(pyxrt.xrt_info_device.max_clock_frequency_mhz),
            mechanical=self.handle.get_info(pyxrt.xrt_info_device.mechanical),
            memory=self.handle.get_info(pyxrt.xrt_info_device.memory),
            name=self.handle.get_info(pyxrt.xrt_info_device.name),
            pcie_info=self.handle.get_info(pyxrt.xrt_info_device.pcie_info),
            thermal=self.handle.get_info(pyxrt.xrt_info_device.thermal),
            vmr=self.handle.get_info(pyxrt.xrt_info_device.vmr),
        )
        return info

    @property
    def name(self):
        return self._info.name

    @property
    def clocks(self):
        """Runtime clocks. This dictionary provides the actual
        clock frequencies that the hardware is running at.
        Frequencies are expressed in Mega Hertz.
        """
        clks = {}
        idx = 0
        for clk in self._info.max_clock_frequency_mhz:
            if clk != 0:
                clks["clock" + str(idx)] = {"frequency": clk}
                idx += 1
        return clks

    @property
    def sensors(self): #TO-DO
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
        try:
            bo.sync(pyxrt.xclBOSyncDirection.XCL_BO_SYNC_BO_TO_DEVICE)
        except Exception as e:
            raise RuntimeError(f"Buffer Flush Failed: {str(e)}")
        
    def invalidate(self, bo, offset, ptr, size):
        try:
            bo.sync(pyxrt.xclBOSyncDirection.XCL_BO_SYNC_BO_FROM_DEVICE)
        except Exception as e:
            raise RuntimeError(f"Buffer Invalidate Failed: {str(e)}")
        
    def allocate_bo(self, size, idx, cacheable):
        flags = pyxrt.bo.flags.normal
        if cacheable:
            flags = pyxrt.bo.flags.cacheable
        
        # Workaround for XRT v2.17 4KB threshold issue:
        # Small buffers (<4KB) get 64-bit addresses, large buffers (>=4KB) get 32-bit addresses
        # Force minimum allocation of 8KB to ensure 32-bit addresses for DMA compatibility
        actual_size = max(size, 8192)  # 8KB minimum
        
        try: 
            bo = pyxrt.bo(self.handle, actual_size, flags, idx)
        except Exception as e:
            raise RuntimeError(f"BO allocation failed: {e}")
        if bo is None:
            raise RuntimeError("BO handle is invalid (None)")
        return bo
   
    def buffer_write(self, bo, bo_offset, buf, buf_offset=0, count=-1):
        view = memoryview(buf).cast("B")
        if count == -1:
            view = view[buf_offset:]
        else:
            view = view[buf_offset:buf_offset + count]
        ptr = (ctypes.c_char * len(view)).from_buffer(view)
        try:
            bo.write(ptr, len(view), bo_offset)
        except Exception as e:
            raise RuntimeError(f"Buffer Write Failed: {str(e)}")

    def buffer_read(self, bo, bo_offset, buf, buf_offset=0, count=-1):
        view = memoryview(buf).cast("B")
        if view.readonly:
            raise RuntimeError("Buffer not writable")
        if count == -1:
            view = view[buf_offset:]
        else:
            view = view[buf_offset:buf_offset + count]
        ptr = (ctypes.c_char * len(view)).from_buffer(view)
        bo.read(ptr, len(view), bo_offset)

    def map_bo(self, bo):
        ptr = bo.map()  
        size = bo.size()  

        if size == 0:
            raise RuntimeError("Failed to get buffer properties")
        if not isinstance(ptr, memoryview):
            raise RuntimeError("Mapped pointer is not of type memoryview")

        return ptr 

    def get_device_address(self, bo):
        return bo.address()


    def close(self):
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

    def _xrt_download(self, data):
        # Load the xclbin from the in-memory buffer
        with open("loaded.xclbin", "wb") as f:  # Open file in binary write mode
            f.write(data)
        try:
            uuid = self.handle.load_xclbin("loaded.xclbin")
        except Exception as e:
            print(f"Error loading xclbin: {e}")
            raise

    def gen_cache(self, bitstream, parser=None):
        pass

    def download(self, bitstream, parser=None):
        with open(bitstream.bitfile_name, "rb") as f:
            data = f.read()
        self._xrt_download(data)
        super().post_download(bitstream, parser)

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
