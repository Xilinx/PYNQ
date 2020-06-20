import pynq
import pytest
import struct

from .mock_devices import *

BASE_ADDRESS = 0x20000
ADDR_RANGE = 0x10000

TEST_DATA = [
    (4, 1234, struct.pack('I', 1234)),
    (16, bytes(range(16)), bytes(range(16)))
]

def test_mmap_read():
    device = MockMemoryMappedDevice('test_mmap_read')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    assert (BASE_ADDRESS, ADDR_RANGE) in device.regions
    region = device.regions[(BASE_ADDRESS, ADDR_RANGE)]
    testdata = struct.pack('I', 1234)
    region[4:8] = testdata
    readvalue = mmio.read(4)
    assert readvalue == 1234
    device.close()

@pytest.mark.parametrize('transaction', TEST_DATA)
def test_mmap_write(transaction):
    offset, pyobj, bytesobj = transaction
    device = MockMemoryMappedDevice('test_mmap_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    assert (BASE_ADDRESS, ADDR_RANGE) in device.regions
    region = device.regions[(BASE_ADDRESS, ADDR_RANGE)]
    mmio.write(offset, pyobj)
    memoryval = region[offset:offset+len(bytesobj)]
    assert memoryval == bytesobj
    device.close()


def test_reg_read():
    device = MockRegisterDevice('test_reg_read')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    testdata = struct.pack('I', 1234)
    with device.check_transactions([(BASE_ADDRESS + 4, testdata)], []):
        read = mmio.read(4)
    assert read == 1234
    device.close()


@pytest.mark.parametrize('transaction', TEST_DATA)
def test_reg_write(transaction):
    offset, pyobj, bytesobj = transaction
    device = MockRegisterDevice('test_reg_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with device.check_transactions([], [(BASE_ADDRESS+offset, bytesobj)]):
        mmio.write(offset, pyobj)
    device.close()


def test_no_capability():
    device = MockDeviceBase('test_no_capability')
    with pytest.raises(ValueError) as excinfo:
        mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    assert str(excinfo.value) == "Device does not have capabilities for MMIO"
    device.close()


@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_negative_addr(DeviceClass):
    device = DeviceClass('test_negative_addr')
    with pytest.raises(ValueError) as excinfo:
        mmio = pynq.MMIO(-BASE_ADDRESS, ADDR_RANGE, device=device)
    assert str(excinfo.value) == "Base address or length cannot be negative."
    device.close()
   

@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_negative_offset_read(DeviceClass):
    device = DeviceClass('test_negative_offset_read')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.read(-4)
    assert str(excinfo.value) == "Offset cannot be negative."
    device.close()
   

@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_negative_offset_write(DeviceClass):
    device = DeviceClass('test_negative_offset_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.write(-4, 1234)
    assert str(excinfo.value) == "Offset cannot be negative."
    device.close()
   

@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_unaligned_offset_write(DeviceClass):
    device = DeviceClass('test_unaligned_offset_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(MemoryError) as excinfo:
        mmio.write(2, 1234)
    assert str(excinfo.value) == 'Unaligned write: offset must be multiple of 4.'
    device.close()
   

@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_unaligned_offset_read(DeviceClass):
    device = DeviceClass('test_unaligned_offset_read')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(MemoryError) as excinfo:
        mmio.read(2)
    assert str(excinfo.value) == 'Unaligned read: offset must be multiple of 4.'
    device.close()
   

@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_long_read(DeviceClass):
    device = DeviceClass('test_long_read')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.read(4, 8)
    assert str(excinfo.value) == "MMIO currently only supports 4-byte reads."
    device.close()
   

@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_float_write(DeviceClass):
    device = DeviceClass('test_float_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.write(4, 8.5)
    assert str(excinfo.value) == "Data type must be int or bytes."
    device.close()


@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_oob_write(DeviceClass):
    device = DeviceClass('test_oob_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.write(ADDR_RANGE, 1234)
    device.close()


@pytest.mark.parametrize('DeviceClass', [MockMemoryMappedDevice, MockRegisterDevice])
def test_oob_read(DeviceClass):
    device = DeviceClass('test_oob_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.read(ADDR_RANGE)
    device.close()


def test_mmap_debug_read(capsys):
    device = MockMemoryMappedDevice('test_mmap_debug_read')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device, debug=True)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: MMIO(address, size) = ({BASE_ADDRESS:x}, {ADDR_RANGE:x} bytes).\n"
    assert (BASE_ADDRESS, ADDR_RANGE) in device.regions
    region = device.regions[(BASE_ADDRESS, ADDR_RANGE)]
    testdata = struct.pack('I', 1234)
    region[4:8] = testdata
    readvalue = mmio.read(4)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: Reading 4 bytes from offset 4\n"
    assert readvalue == 1234
    device.close()

def test_mmap_debug_write(capsys):
    offset, pyobj, bytesobj = TEST_DATA[0]
    device = MockMemoryMappedDevice('test_mmap_debug_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device, debug=True)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: MMIO(address, size) = ({BASE_ADDRESS:x}, {ADDR_RANGE:x} bytes).\n"
    assert (BASE_ADDRESS, ADDR_RANGE) in device.regions
    region = device.regions[(BASE_ADDRESS, ADDR_RANGE)]
    mmio.write(offset, pyobj)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: Writing 4 bytes to offset {offset:x}: {pyobj:x}\n"
    memoryval = region[offset:offset+len(bytesobj)]
    assert memoryval == bytesobj
    device.close()


def test_reg_debug_read(capsys):
    device = MockRegisterDevice('test_reg_debug_read')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device, debug=True)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: MMIO(address, size) = ({BASE_ADDRESS:x}, {ADDR_RANGE:x} bytes).\n"
    testdata = struct.pack('I', 1234)
    with device.check_transactions([(BASE_ADDRESS + 4, testdata)], []):
        read = mmio.read(4)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: Reading 4 bytes from offset 4\n"
    assert read == 1234
    device.close()


def test_reg_debug_write(capsys):
    offset, pyobj, bytesobj = TEST_DATA[0]
    device = MockRegisterDevice('test_reg_debug_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device, debug=True)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: MMIO(address, size) = ({BASE_ADDRESS:x}, {ADDR_RANGE:x} bytes).\n"
    with device.check_transactions([], [(BASE_ADDRESS+offset, bytesobj)]):
        mmio.write(offset, pyobj)
    out, err = capsys.readouterr()
    assert out == f"MMIO Debug: Writing 4 bytes to offset {offset:x}: {pyobj:x}\n"
    device.close()


def test_active_device():
    device = MockRegisterDevice('test_active_device')
    pynq.Device.active_device = device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE)
    testdata = struct.pack('I', 1234)
    with device.check_transactions([(BASE_ADDRESS + 4, testdata)], []):
        read = mmio.read(4)
    assert read == 1234
    assert mmio.device == device
    pynq.Device.active_device = None
    device.close()


def test_mmap_bad_length_write():
    device = MockMemoryMappedDevice('test_mmap_bad_length_write')
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(MemoryError) as excinfo:
        mmio.write(4, bytes(range(6)))
    assert str(excinfo.value) == "Unaligned write: data length must be multiple of 4."
    device.close()

