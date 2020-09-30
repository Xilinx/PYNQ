import collections
import numpy as np
import pynq
import weakref


class MockDeviceBase(pynq.Device):
    def __init__(self, tag):
        super().__init__(tag)


class MockRegisterDevice(MockDeviceBase):
    def __init__(self, tag):
        super().__init__(tag)
        self.capabilities = {'REGISTER_RW': True}
        self.reads = collections.deque()
        self.writes = collections.deque()

    def check_transactions(self, reads, writes):
        self.reads = collections.deque(reads)
        self.writes = collections.deque(writes)
        return self

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        assert self.reads == collections.deque()
        assert self.writes == collections.deque()

    def read_registers(self, address, length):
        expected = self.reads.popleft()
        assert expected[0] == address
        assert len(expected[1]) == length
        return bytes(memoryview(expected[1]))

    def write_registers(self, address, data):
        expected = self.writes.popleft()
        assert expected[0] == address
        assert expected[1] == data


class MockMemoryMappedDevice(MockDeviceBase):
    def __init__(self, tag):
        super().__init__(tag)
        self.capabilities = {'MEMORY_MAPPED': True}
        self.regions = {}

    def mmap(self, base_addr, length):
        for (region_base, region_length), region in self.regions.items():
            if (base_addr >= region_base and
                base_addr < region_base + region_length):
                if base_addr + length <= region_base + region_length:
                    offset = base_addr - region_base
                    return np.frombuffer(region,dtype='u1', offset=offset, count=length)
                else:
                    raise RuntimeError("Map failed - allocate largest region first")
        buf = bytearray(length)
        self.regions[(base_addr, length)] = buf
        return np.frombuffer(buf, dtype='u4')


class MockAllocateDevice(MockDeviceBase):
    def __init__(self, tag):
        super().__init__(tag)
        self.allocates = collections.deque()
        self.flushes = collections.deque()
        self.invalidates = collections.deque()
        self._allocated = []

    def allocate(self, shape, dtype):
        bo, coherent, address = self.allocates.popleft()
        buf = pynq.buffer.PynqBuffer(shape, dtype, device=self,
                                     bo=bo, coherent=coherent,
                                     device_address=address)
        self._allocated.append(weakref.ref(buf))
        return buf

    def flush(self, bo, offset, vaddr, length):
        expected_bo, expected_offset, expected_length = self.flushes.popleft()
        assert expected_bo == bo
        assert expected_offset == offset
        assert expected_length == length

    def invalidate(self, bo, offset, vaddr, length):
        expected_bo, expected_offset, expected_length = \
            self.invalidates.popleft()
        assert expected_bo == bo
        assert expected_offset == offset
        assert expected_length == length

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        assert self.allocates == collections.deque()
        assert self.flushes == collections.deque()
        assert self.invalidates == collections.deque()

    def check_memops(self, allocates=[], flushes=[], invalidates=[]):
        self.allocates = collections.deque(allocates)
        self.flushes = collections.deque(flushes)
        self.invalidates = collections.deque(invalidates)
        return self

    def check_allocated(self):
        for ref in self._allocated:
            assert ref() is None


class MockDownloadableDevice(MockDeviceBase):
    def __init__(self, tag):
        super().__init__(tag)
        self.operations = []

    def download(self, bitstream, parser=None):
        self.operations.append(('download', bitstream, parser))

    def remove_device_tree(self, dtbo):
        self.operations.append(('remove_device_tree', dtbo))

    def insert_device_tree(self, dtbo):
        self.operations.append(('insert_device_tree', dtbo))


class MockIPDevice(MockDeviceBase):
    def __init__(self, ip, tag):
        super().__init__(tag)
        self.capabilities = {'REGISTER_RW': True}
        self.ip = ip

    def _find_ip(self, address, length):
        for ip in self.ip:
            if address >= ip.lo_address and address < ip.hi_address:
                assert address + length <= ip.hi_address
                return ip

    def read_registers(self, address, length):
        ip = self._find_ip(address, length)
        return ip.read(address - ip.lo_address, length)

    def write_registers(self, address, data):
        ip = self._find_ip(address, len(data))
        return ip.write(address - ip.lo_address, data)
