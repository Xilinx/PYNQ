import pynq
import pytest
import struct

from .mock_devices import MockDeviceBase, MockRegisterDevice
from .mock_devices import MockMemoryMappedDevice


BASE_ADDRESS = 0x20000
ADDR_RANGE = 0x10000


TEST_DATA = [
    (4, 1234, struct.pack('I', 1234)),
    (16, bytes(range(16)), bytes(range(16)))
]


@pytest.fixture
def register_device():
    device = MockRegisterDevice('register_device')
    yield device
    device.close()


@pytest.fixture
def mmap_device():
    device = MockMemoryMappedDevice('mmap_device')
    yield device
    device.close()


@pytest.fixture(params=[MockRegisterDevice, MockMemoryMappedDevice])
def device(request):
    device = request.param('device')
    yield device
    device.close()


def test_mmap_read(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    assert (BASE_ADDRESS, ADDR_RANGE) in device.regions
    region = device.regions[(BASE_ADDRESS, ADDR_RANGE)]
    testdata = struct.pack('I', 1234)
    region[4:8] = testdata
    readvalue = mmio.read(4)
    assert readvalue == 1234


@pytest.mark.parametrize('transaction', TEST_DATA)
def test_mmap_write(transaction, mmap_device):
    offset, pyobj, bytesobj = transaction
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    assert (BASE_ADDRESS, ADDR_RANGE) in device.regions
    region = device.regions[(BASE_ADDRESS, ADDR_RANGE)]
    mmio.write(offset, pyobj)
    memoryval = region[offset:offset+len(bytesobj)]
    assert memoryval == bytesobj


def test_reg_read(register_device):
    device = register_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    testdata = struct.pack('I', 1234)
    with device.check_transactions([(BASE_ADDRESS + 4, testdata)], []):
        read = mmio.read(4)
    assert read == 1234


@pytest.mark.parametrize('transaction', TEST_DATA)
def test_reg_write(transaction, register_device):
    offset, pyobj, bytesobj = transaction
    device = register_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with device.check_transactions([], [(BASE_ADDRESS+offset, bytesobj)]):
        mmio.write(offset, pyobj)


def test_no_capability():
    device = MockDeviceBase('test_no_capability')
    with pytest.raises(ValueError) as excinfo:
        mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)  # NOQA
    assert str(excinfo.value) == "Device does not have capabilities for MMIO"
    device.close()


def test_negative_addr(device):
    with pytest.raises(ValueError) as excinfo:
        mmio = pynq.MMIO(-BASE_ADDRESS, ADDR_RANGE, device=device)  # NOQA
    assert str(excinfo.value) == "Base address or length cannot be negative."


def test_negative_offset_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.read(-4)
    assert str(excinfo.value) == "Offset cannot be negative."


def test_negative_offset_write(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.write(-4, 1234)
    assert str(excinfo.value) == "Offset cannot be negative."


def test_unaligned_offset_write(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(MemoryError) as excinfo:
        mmio.write(2, 1234)
    assert str(excinfo.value) == \
           'Unaligned write: offset must be multiple of 4.'


def test_unaligned_offset_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(MemoryError) as excinfo:
        mmio.read(2)
    assert str(excinfo.value) == \
           'Unaligned read: offset must be multiple of 4.'


def test_long_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.read(4, 8)
    assert str(excinfo.value) == \
           "MMIO currently only supports 4-byte reads."


def test_float_write(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.write(4, 8.5)
    assert str(excinfo.value) == "Data type must be int or bytes."


def test_oob_write(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.write(ADDR_RANGE, 1234)


def test_oob_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.read(ADDR_RANGE)


def test_active_device(register_device):
    device = register_device
    pynq.Device.active_device = device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE)
    testdata = struct.pack('I', 1234)
    with device.check_transactions([(BASE_ADDRESS + 4, testdata)], []):
        read = mmio.read(4)
    assert read == 1234
    assert mmio.device == device
    pynq.Device.active_device = None


def test_mmap_bad_length_write(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(MemoryError) as excinfo:
        mmio.write(4, bytes(range(6)))
    assert str(excinfo.value) == \
           "Unaligned write: data length must be multiple of 4."
