import numpy as np
import pynq
import pytest
import struct
import warnings


from .mock_devices import MockDeviceBase, MockRegisterDevice
from .mock_devices import MockMemoryMappedDevice


BASE_ADDRESS = 0x20000
ADDR_RANGE = 0x10000


TEST_DATA = [
    (4, 1234, struct.pack('I', 1234)),
    (16, bytes(range(16)), bytes(range(16)))
]

TEST_READ_DATA = [
    (BASE_ADDRESS + 4, struct.pack('I', 0x12345678)),
    (BASE_ADDRESS + 8, struct.pack('I', 0xbeefcafe))
]

TEST_DATA_NUMPY = [
    (300, int(53970361), int(53970361).to_bytes(4, 'little')),
    (300, np.uint32(543394), np.uint32(543394).tobytes()),
    (256, np.int32(-14921033), np.int32(-14921033).tobytes()),
    (248, np.uint16(12045), np.int32(12045).tobytes()),
    (260, np.int16(-12045), np.int32(-12045).tobytes()),
    (260, np.uint8(248), np.int32(248).tobytes()),
    (200, np.int8(-99), np.int32(-99).tobytes()),
    (260, np.uint64(4181616581), np.uint64(4181616581).tobytes()),
    (200, np.int64(-14103463169), np.int64(-14103463169).tobytes()),
]

TEST_DATA_FLOAT = [
    (8, 98.576, int(0x42c526e9).to_bytes(4, 'little')),
    (48, np.single(-32.587), int(0xc2025917).to_bytes(4, 'little'))
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


@pytest.mark.parametrize('transaction', TEST_DATA_NUMPY)
def test_reg_write_numpy(transaction, register_device):
    offset, value, bytesobj = transaction
    device = register_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with device.check_transactions([], [(BASE_ADDRESS+offset, bytesobj)]):
        mmio.write(offset, value)


@pytest.mark.parametrize('transaction', TEST_DATA_NUMPY)
def test_reg_read_numpy(transaction, mmap_device):
    offset, value, bytesobj = transaction
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    mmio.write(offset, value)
    read = mmio.read(offset, dtype=type(value))
    assert value == read


@pytest.mark.parametrize('transaction', TEST_DATA_FLOAT)
def test_reg_write_float(transaction, register_device):
    offset, pyobj, bytesobj = transaction
    device = register_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with device.check_transactions([], [(BASE_ADDRESS+offset, bytesobj)]):
        mmio.write(offset, pyobj)


def test_reg_read_float(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    offset, testdata = (956, np.float32(102.687))
    mmio.write(offset, testdata)
    read = mmio.read(offset, dtype=type(testdata))
    assert np.isclose(read, testdata, rtol=1e-05, atol=1e-08, equal_nan=False)


def test_reg_read_unsopported_type(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    offset, value = (956, np.float16(102.687))
    with pytest.raises(ValueError) as excinfo:
        read = mmio.read(offset, dtype=type(value))
    assert str(excinfo.value) == "dtype \'{}\' is not supported".format(type(value))


def test_reg_write_unsupported_type(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    value = np.half(20.22)
    with pytest.raises(ValueError) as excinfo:
        mmio.write(4, value)
    assert str(excinfo.value) == "dtype \'{}\' is not supported".format(type(value))


def test_oob_write(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.write(ADDR_RANGE, 1234)


def test_oob_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.read(ADDR_RANGE)


def test_deprecated_debug_keyword(mmap_device):
    device = mmap_device
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter("always")
        _ = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE,
                      device=device, debug=True)
        assert len(w) == 1, 'No warnings when providing keyword debug'
        assert issubclass(w[-1].category, DeprecationWarning), \
            'Warning is not of type DeprecationWarning'
        assert "debug" in str(w[-1].message), \
            'Warning not related to keyword debug'

def test_deprecated_length_keyword(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter("always")
        read = mmio.read(4, length=1)
        assert len(w) == 1, 'No warnings when providing keyword debug'
        assert issubclass(w[-1].category, DeprecationWarning), \
            'Warning is not of type DeprecationWarning'
        assert "length" in str(w[-1].message), \
            'Keyword length has been deprecated.'

def test_deprecated_word_order_keyword(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter("always")
        read = mmio.read(4, word_order='little')
        assert len(w) == 1, 'No warnings when providing keyword debug'
        assert issubclass(w[-1].category, DeprecationWarning), \
            'Warning is not of type DeprecationWarning'
        assert "word_order" in str(w[-1].message), \
            'Keyword word_order has been deprecated.'
