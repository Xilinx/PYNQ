#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import numpy as np
import struct



PTR_OFFSET = 0x80000000

# On aarch64 systems we can suffer from SEGFAULTS in memcpy if
# unaligned address are copied
def _safe_copy(dest, src):
    for i in range(len(src)):
        dest[i] = src[i]


class SimpleMBChannel:
    def __init__(self, buffer, offset=0, length=0):
        self.control_array = np.frombuffer(buffer, count=2,
                                           offset=offset, dtype=np.uint32)
        if not length:
            length = len(buffer) - offset
        self.data_array = np.frombuffer(buffer, count=(length - 8),
                                        offset=offset + 8, dtype=np.uint8)
        self.length = length - 8

    def write(self, b):
        written = int(self.control_array[0])
        read = self._safe_control_read(1)
        available = (read - written - 1 + 2 * self.length) % self.length
        to_write = min(len(b), available)
        write_array = np.fromstring(b, np.uint8)
        end_block = min(to_write, self.length - written)
        _safe_copy(self.data_array[written:written + end_block],
                   write_array[0:end_block])
        # Automatically wrap the write if necessary
        if end_block < to_write:
            _safe_copy(self.data_array[0:to_write-end_block],
                       write_array[end_block:to_write])
        # Atomically increase the write pointer to make data handling easier
        self.control_array[0] = (written + to_write) % self.length
        return to_write

    def bytes_available(self):
        written = int(self._safe_control_read(0))
        read = self._safe_control_read(1)
        available = (written - read + self.length) % self.length
        return available

    def buffer_space(self):
        written = int(self.control_array[0])
        read = self._safe_control_read(1)
        available = (read - written - 1 + 2 * self.length) % self.length
        return available

    def read_upto(self, n=-1):
        written = int(self._safe_control_read(0))
        read = self.control_array[1]
        available = (written - read + self.length) % self.length
        if available == 0:
            return b''
        if n > 0 and available > n:
            available = n
        read_array = np.empty([available], dtype=np.uint8)
        end_block = min(available, self.length - read)
        _safe_copy(read_array[0:end_block],
                   self.data_array[read:read + end_block])
        if end_block < available:
            _safe_copy(read_array[end_block:available],
                       self.data_array[0:available - end_block])
        self.control_array[1] = (read + available) % self.length
        return read_array.tobytes()

    def read(self, n=-1):
        data = self.read_upto(n)
        while len(data) != n and n != -1:
            assert(len(data) < n)
            data += self.read_upto(n-len(data))
        return data

    def _safe_control_read(self, index):
        last_value = self.control_array[index]
        value = self.control_array[index]
        while value != last_value:
            last_value = value
            value = self.control_array[index]
        return value


_short_struct = struct.Struct('h')
_ushort_struct = struct.Struct('H')
_int_struct = struct.Struct('i')
_uint_struct = struct.Struct('I')
_float_struct = struct.Struct('f')


class SimpleMBStream:
    def __init__(self, iop, read_offset=0xF400, write_offset=0xF000):
        self.read_channel = SimpleMBChannel(iop.mmio.array, offset=read_offset,
                                            length=0x400)
        self.write_channel = SimpleMBChannel(iop.mmio.array,
                                             offset=write_offset, length=0x400)

    def read(self, n=-1):
        return self.read_channel.read(n)

    def write(self, b):
        return self.write_channel.write(b)

    def write_byte(self, b):
        return self.write(bytes([b]))

    def write_int16(self, i):
        return self.write(_short_struct.pack(i))

    def write_int32(self, i):
        return self.write(_int_struct.pack(i))

    def write_uint16(self, u):
        return self.write(_ushort_struct.pack(u))

    def write_uint32(self, u):
        return self.write(_uint_struct.pack(u))

    def write_string(self, s):
        data = _ushort_struct.pack(len(s)) + s
        return self.write(data)

    def write_float(self, f):
        return self.write(_float_struct.pack(f))

    def write_address(self, p, adjust=True):
        if adjust:
            p = p | PTR_OFFSET
        return self.write_uint32(p)

    def bytes_available(self):
        return self.read_channel.bytes_available()

    def buffer_space(self):
        return self.write_channel.buffer_space()

    def read_byte(self):
        return self.read(1)[0]

    def read_int16(self):
        return _short_struct.unpack(self.read(2))[0]

    def read_int32(self):
        return _int_struct.unpack(self.read(4))[0]

    def read_uint16(self):
        return _ushort_struct.unpack(self.read(2))[0]

    def read_uint32(self):
        return _uint_struct.unpack(self.read(4))[0]

    def read_string(self):
        length = _ushort_struct.unpack(self.read(2))[0]
        return self.read(length)

    def read_float(self):
        return _float_struct.unpack(self.read(4))[0]


class InterruptMBStream(SimpleMBStream):
    def __init__(self, iop, read_offset=0xF400, write_offset=0xF000):
        super().__init__(iop, read_offset, write_offset)
        self.interrupt = iop.interrupt

    async def wait_for_data_async(self):
        while self.bytes_available() == 0:
            await self.interrupt.wait()
            self.interrupt.clear()

    async def read_async(self):
        data = self.read()
        while not data:
            await self.interrupt.wait()
            data = self.read()
            self.interrupt.clear()
        return data


