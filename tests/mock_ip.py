import struct


class MockIPBase:
    def __init__(self, base_address, address_range):
        self.lo_address = base_address
        self.hi_address = base_address + address_range


class MockRegisterIP(MockIPBase):
    def read(self, address, length):
        assert length == 4
        return struct.pack('I', self.read_register(address))

    def write(self, address, data):
        assert len(data) == 4
        self.write_register(address, struct.unpack('I', data)[0])
