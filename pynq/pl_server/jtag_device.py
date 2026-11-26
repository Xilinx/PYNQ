# Copyright (C) 2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

import collections
from contextlib import ExitStack
import ctypes
from importlib.resources import as_file, files
import math
import os
import queue
import shutil
import signal
import socket
import subprocess
import threading
import time
from pathlib import Path

import numpy as np
from pynq.buffer import PynqBuffer
from pynqmetadata.frontends import Metadata
from pynqmetadata.views.runtime import RuntimeMetadataParser

from .device import Device


def _stop(process, graceful=False):
    if process is None or process.poll() is not None:
        return
    if graceful:
        try:
            process.stdin.write("exit\n")
            process.stdin.flush()
            process.wait(timeout=2)
            return
        except (OSError, subprocess.TimeoutExpired):
            pass
    if os.name == "nt":
        subprocess.run(
            ["taskkill", "/PID", str(process.pid), "/T", "/F"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    else:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        if os.name == "nt":
            process.kill()
        else:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        process.wait(timeout=2)


class _JtagSession:
    _server_lock = threading.Lock()
    _server = None
    _users = 0

    def __init__(self, target):
        self._lock = threading.RLock()
        self._responses = queue.Queue()
        self._messages = collections.deque(maxlen=50)
        self._counter = 0
        self.closed = False
        self._registered = False
        self._vivado = None
        self._reader = None
        self._resources = ExitStack()
        vivado = shutil.which("vivado") or shutil.which("vivado_lab")
        server = shutil.which("hw_server")
        if not vivado or not server:
            raise RuntimeError("Add Vivado or Vivado Lab and hw_server to PATH")
        try:
            self._acquire_server(server)
            script = self._resources.enter_context(
                as_file(files(__package__).joinpath("jtag.tcl"))
            )
            self._vivado = subprocess.Popen(
                [vivado, "-mode", "batch", "-source", str(script), "-notrace", "-nojournal", "-nolog"],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                errors="replace", bufsize=1,
                start_new_session=os.name != "nt",
            )
            self._reader = threading.Thread(target=self._read_output, daemon=True)
            self._reader.start()
            identity = self.request("connect", (target or "").encode().hex(), timeout=120)
            self.target, self.device, self.part = identity.splitlines()
        except BaseException:
            self.close()
            raise

    def _acquire_server(self, executable):
        cls = type(self)
        with cls._server_lock:
            try:
                with socket.create_connection(("127.0.0.1", 3121), timeout=0.2):
                    pass
            except OSError:
                cls._server = subprocess.Popen(
                    [executable, "-s", "TCP:127.0.0.1:3121", "-p0"],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                    start_new_session=os.name != "nt",
                )
                try:
                    for _ in range(120):
                        try:
                            with socket.create_connection(("127.0.0.1", 3121), timeout=0.2):
                                break
                        except OSError:
                            if cls._server.poll() is not None:
                                raise RuntimeError("hw_server exited before opening localhost:3121")
                            time.sleep(0.1)
                    else:
                        raise TimeoutError("hw_server did not open localhost:3121")
                except BaseException:
                    _stop(cls._server)
                    cls._server = None
                    raise
            cls._users += 1
            self._registered = True

    def _read_output(self):
        try:
            for line in self._vivado.stdout:
                line = line.rstrip("\r\n")
                if line.startswith("@@PYNQ@@ "):
                    self._responses.put(line.split(" ", 3))
                else:
                    self._messages.append(line)
        finally:
            self._responses.put(None)

    def request(self, operation, *args, timeout=10):
        with self._lock:
            if self.closed:
                raise RuntimeError("JTAG device is closed")
            self._counter += 1
            identifier = str(self._counter)
            command = " ".join(("pynq_request", identifier, operation, *args)) + "\n"
            try:
                self._vivado.stdin.write(command)
                self._vivado.stdin.flush()
                response = self._responses.get(timeout=timeout)
                if response is None:
                    raise RuntimeError("Vivado exited")
                _, received, status, payload = response
                if received != identifier or status not in ("OK", "ERROR"):
                    raise RuntimeError("Invalid Vivado response")
                result = bytes.fromhex(payload).decode("utf-8")
            except BaseException as exc:
                self.close()
                if isinstance(exc, (KeyboardInterrupt, SystemExit)):
                    raise
                messages = "\n".join(self._messages)
                if isinstance(exc, queue.Empty):
                    raise TimeoutError(f"JTAG {operation} timed out\n{messages}") from exc
                raise RuntimeError(f"JTAG {operation} failed: {exc}\n{messages}") from exc
            if status == "ERROR":
                raise RuntimeError(result)
            return result

    def close(self):
        with self._lock:
            if self.closed:
                return
            self.closed = True
            try:
                _stop(self._vivado, graceful=True)
                if self._reader is not None:
                    self._reader.join(timeout=2)
                if self._vivado is not None:
                    self._vivado.stdin.close()
                    self._vivado.stdout.close()
                self._resources.close()
            finally:
                if self._registered:
                    cls = type(self)
                    with cls._server_lock:
                        self._registered = False
                        cls._users -= 1
                        if not cls._users:
                            _stop(cls._server)
                            cls._server = None


class JtagBuffer(PynqBuffer):
    def __array_finalize__(self, obj):
        super().__array_finalize__(obj)
        self._owns_allocation = False
        self._allocation = (
            getattr(obj, "_allocation", None)
            if obj is not None and np.shares_memory(self, obj) else None
        )

    def freebuffer(self):
        allocation = getattr(self, "_allocation", None)
        if getattr(self, "_owns_allocation", False):
            with self.device.device._lock:
                if allocation[2]:
                    allocation[2] = False
                    self.device._release(*allocation[:2])

    def _check(self):
        if self._allocation is None or not self._allocation[2]:
            raise RuntimeError("JTAG buffer has no live allocation")
        if not self.flags.c_contiguous:
            raise ValueError("JTAG synchronisation requires a contiguous buffer")
        self.device._check()

    def flush(self):
        with self.device.device._lock:
            self._check()
            super().flush()

    def invalidate(self):
        with self.device.device._lock:
            self._check()
            super().invalidate()


class JtagMemory:
    def __init__(self, device, description):
        from pynq.mmio import MMIO

        self.device = device
        self.desc = description
        self.base_address = description["phys_addr"]
        self.size = description["addr_range"]
        self._generation = device._generation
        self.mmio = MMIO(self.base_address, self.size, device=self)
        self.array = self.mmio.array
        self._free = [(0, self.size)]

    def _check(self):
        if self.device._session.closed:
            raise RuntimeError("JTAG device is closed")
        if self._generation is not self.device._generation:
            raise RuntimeError("JTAG memory belongs to a previous overlay")

    def _address(self, offset, length):
        self._check()
        if offset < 0 or length < 0 or offset + length > self.size:
            raise ValueError("Transfer outside JTAG memory")
        return self.base_address + offset

    def has_capability(self, capability):
        return self.device.has_capability(capability)

    def read_registers(self, address, length):
        return self.read_bytes(address - self.base_address, length)

    def write_registers(self, address, data):
        self.write_bytes(address - self.base_address, data)

    def read(self, offset=0, length=4, word_order="little"):
        with self.device._lock:
            self._address(offset, length)
            return self.mmio.read(offset, length, word_order)

    def write(self, offset, value):
        with self.device._lock:
            size = len(value) if isinstance(value, bytes) else 4
            self._address(offset, size)
            self.mmio.write(offset, value)

    def read_bytes(self, offset, length):
        with self.device._lock:
            return self.device.read_registers(self._address(offset, length), length)

    def write_bytes(self, offset, data):
        with self.device._lock:
            self.device.write_registers(self._address(offset, len(data)), data)

    def allocate(self, shape, dtype, **kwargs):
        if kwargs:
            raise TypeError(f"Unsupported JTAG allocation options: {', '.join(kwargs)}")
        shape = (shape,) if isinstance(shape, (int, np.integer)) else tuple(shape)
        dtype = np.dtype(dtype)
        if dtype.hasobject:
            raise TypeError("JTAG buffers cannot contain Python objects")
        length = math.prod(shape) * dtype.itemsize
        if any(size < 0 for size in shape) or length <= 0:
            raise ValueError("JTAG buffer size must be positive")
        reserved = (length + 3) & ~3
        with self.device._lock:
            self._check()
            for index, (offset, available) in enumerate(self._free):
                if available >= reserved:
                    if available == reserved:
                        self._free.pop(index)
                    else:
                        self._free[index] = (offset + reserved, available - reserved)
                    break
            else:
                raise MemoryError("JTAG memory has insufficient free space")
            try:
                buffer = JtagBuffer(
                    shape, dtype, device=self, device_address=self.base_address + offset,
                    bo=offset, coherent=False,
                )
            except BaseException:
                self._release(offset, reserved)
                raise
            buffer._allocation = [offset, reserved, True]
            buffer._owns_allocation = True
            return buffer

    def _release(self, offset, length):
        with self.device._lock:
            self._free.append((offset, length))
            self._free.sort()
            merged = []
            for start, size in self._free:
                if merged and merged[-1][0] + merged[-1][1] == start:
                    merged[-1] = (merged[-1][0], merged[-1][1] + size)
                else:
                    merged.append((start, size))
            self._free = merged

    def flush(self, bo, offset, pointer, size):
        with self.device._lock:
            self._address(bo + offset, size)
            contents = ctypes.string_at(pointer, size)
            start = bo + offset
            if start % 4 == 0 and size % 4 == 0:
                self.write_bytes(start, contents)
                return
            first = start & ~3
            last = (start + size + 3) & ~3
            data = bytearray(self.read_bytes(first, last - first))
            data[start - first:start - first + size] = contents
            self.write_bytes(first, data)

    def invalidate(self, bo, offset, pointer, size):
        with self.device._lock:
            start = bo + offset
            self._address(start, size)
            first = start & ~3
            last = (start + size + 3) & ~3
            data = self.read_bytes(first, last - first)
            ctypes.memmove(pointer, data[start - first:start - first + size], size)


class JtagDevice(Device):
    """A host-controlled FPGA containing one 32-bit JTAG-to-AXI master.

    Requires Vivado or Vivado Lab and hw_server on PATH. Pass a complete
    hardware target name when more than one cable is connected. Close the
    device, preferably using a context manager, to release its processes.
    """

    def __init__(self, target=None):
        self._lock = threading.RLock()
        self._session = _JtagSession(target)
        super().__init__(f"jtag:{self._session.target}:{self._session.device}")
        self.part = self._session.part
        self.capabilities = {"REGISTER_RW": True}
        self.clear_dict()
        self.bitfile_name = ""
        self.timestamp = ""
        self._generation = object()
        self._memories = {}

    def set_bitfile_name(self, bitfile_name):
        with self._lock:
            self.parser = self.get_bitfile_metadata(bitfile_name)

    def get_bitfile_metadata(self, bitfile_name, partial=False):
        if partial:
            raise NotImplementedError("JTAG partial bitstreams are unavailable")
        hwh = Path(bitfile_name).with_suffix(".hwh")
        if not hwh.is_file():
            raise FileNotFoundError(hwh)
        metadata = Metadata(input=hwh)
        masters = [
            core for core in metadata.blocks.values()
            if core.vlnv.name == "jtag_axi"
        ]
        if len(masters) != 1:
            raise ValueError(f"Expected one JTAG AXI master; found {len(masters)}")
        return RuntimeMetadataParser(metadata, manager=masters[0])

    def download(self, bitstream, parser=None):
        if bitstream.partial:
            raise NotImplementedError("JTAG partial bitstreams are unavailable")
        with self._lock:
            if parser is None:
                parser = self.get_bitfile_metadata(bitstream.bitfile_name)
            self.timestamp = ""
            self.bitfile_name = ""
            self._generation = object()
            self._memories.clear()
            self._session.request("program", str(bitstream.bitfile_name).encode().hex(), timeout=120)
            self.parser = parser
            self.systemgraph = parser.systemgraph
            self.post_download(bitstream, parser)

    def _region(self, address, length):
        if (address < 0 or address > 0xFFFFFFFF or address + length > 0x100000000
                or length < 0 or address % 4 or length % 4):
            raise ValueError("JTAG transfers require aligned 32-bit addresses and lengths")
        for desc in (*self.ip_dict.values(), *self.mem_dict.values()):
            base = desc["phys_addr"]
            size = desc["addr_range"]
            if base <= address and address + length <= base + size:
                return desc
        raise ValueError("JTAG transfer outside the overlay address map")

    def _chunks(self, address, length, memory):
        while length:
            words = min(length // 4, 256 if memory else 1, (4096 - address % 4096) // 4)
            yield address, words
            address += 4 * words
            length -= 4 * words

    def read_registers(self, address, length):
        with self._lock:
            region = self._region(address, length)
            if not length:
                return b""
            if not self.timestamp:
                raise RuntimeError("No JTAG overlay is programmed")
            result = bytearray()
            for at, count in self._chunks(address, length, region["memtype"] == "MEMORY"):
                raw = self._session.request("read", f"{at:08X}", str(count))
                words = raw.replace("_", "").replace(" ", "")
                if len(words) != count * 8:
                    raise RuntimeError(f"JTAG read returned {len(words) // 8} words, expected {count}")
                for index in range(count):
                    start = (count - index - 1) * 8
                    result.extend(int(words[start:start + 8], 16).to_bytes(4, "little"))
            return bytes(result)

    def write_registers(self, address, data):
        with self._lock:
            if not isinstance(data, bytes):
                data = bytes(data)
            region = self._region(address, len(data))
            if not data:
                return
            if not self.timestamp:
                raise RuntimeError("No JTAG overlay is programmed")
            offset = 0
            for at, count in self._chunks(address, len(data), region["memtype"] == "MEMORY"):
                words = [f"{int.from_bytes(data[offset + i * 4:offset + (i + 1) * 4], 'little'):08X}" for i in range(count)]
                self._session.request("write", f"{at:08X}", str(count), "_".join(reversed(words)))
                offset += count * 4

    def get_memory(self, description):
        with self._lock:
            if not self.timestamp:
                raise RuntimeError("No JTAG overlay is programmed")
            key = (description["phys_addr"], description["addr_range"])
            for region in self.mem_dict.values():
                if key == (region["phys_addr"], region["addr_range"]):
                    if key not in self._memories:
                        self._memories[key] = JtagMemory(self, region)
                    return self._memories[key]
            raise ValueError("Memory is not in the programmed overlay")

    def allocate(self, *args, **kwargs):
        raise NotImplementedError("Select a JTAG-accessible memory with allocate(target=memory)")

    def insert_device_tree(self, *args, **kwargs):
        raise NotImplementedError("JTAG devices have no target device tree")

    def remove_device_tree(self, *args, **kwargs):
        raise NotImplementedError("JTAG devices have no target device tree")

    def close(self):
        with self._lock:
            self._session.close()

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()
