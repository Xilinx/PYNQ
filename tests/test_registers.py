import pytest
import pynq
import operator
import struct

import numpy as np

# Each vector is a tuple of
#  1. Register length
#  2. Starting value
#  3. Slice
#  4. Update Value
#  5. Expected get_item pre-update
#  6. Expected register value post-update
TEST_VECTORS = {
    "single-bit-set-32":
        (32, 0x0000_0000, 4, 1, 0, 0x0000_0010, 1),
    "single-bit-clear-32":
        (32, 0x0000_0010, 4, 0, 1, 0x0000_0000, 1),
    "single-bit-range-set-32":
        (32, 0x0000_0000, slice(4, 4), 1, 0, 0x0000_0010, 1),
    "single-bit-range-clear-32":
        (32, 0x0000_0010, slice(4, 4), 0, 1, 0x0000_0000, 1),
    "multi-bit-set-32":
        (32, 0x0000_0000, slice(7, 4), 0xF, 0, 0x0000_00F0, 4),
    "multi-bit-clear-32":
        (32, 0x0000_00F0, slice(7, 4), 0x0, 0xF, 0x0000_0000, 4),
    "multi-bit-normal-32":
        (32, 0x0000_0010, slice(7, 4), 0x1, 0x1, 0x0000_0010, 4),
    "multi-bit-reverse-32":
        (32, 0x0000_0010, slice(4, 7), 0x1, 0x8, 0x0000_0080, 4),
    "whole-reg-32":
        (32, 0x1234_5678, slice(None, None, None),
         0x8765_4321, 0x1234_5678, 0x8765_4321, 32),
    "whole-reg-forward-32":
        (32, 0x1234_5678, slice(None, None, -1),
         0x8765_4321, 0x1234_5678, 0x8765_4321, 32),
    "whole-reg-reverse-32":
        (32, 0x1234_5678, slice(None, None, 1),
         0x1234_5678, 0x1E6A_2C48, 0x1E6A_2C48, 32),
    "lower-reg-32":
        (32, 0x1234_5678, slice(15, None, None),
         0x1234, 0x5678, 0x1234_1234, 16),
    "lower-reg-forward-32":
        (32, 0x1234_5678, slice(15, None, -1),
         0x1234, 0x5678, 0x1234_1234, 16),
    "lower-reg-reverse-32":
        (32, 0x1234_5678, slice(None, 15, 1),
         0x1234, 0x1E6A, 0x1234_2C48, 16),
    "upper-reg-32":
        (32, 0x1234_5678, slice(None, 16, None),
         0x5678, 0x1234, 0x56785678, 16),
    "upper-reg-forward-32":
        (32, 0x1234_5678, slice(None, 16, -1),
         0x5678, 0x1234, 0x5678_5678, 16),
    "upper-reg-reverse-32":
        (32, 0x1234_5678, slice(16, None, 1),
         0x5678, 0x2C48, 0x1E6A_5678, 16),
    "single-bit-set-64":
        (64, 0x0000_0000, 4, 1, 0, 0x0000_0010, 1),
    "single-bit-clear-64":
        (64, 0x0000_0010, 4, 0, 1, 0x0000_0000, 1),
    "single-bit-range-set-64":
        (64, 0x0000_0000, slice(4, 4), 1, 0, 0x0000_0010, 1),
    "single-bit-range-clear-64":
        (64, 0x0000_0010, slice(4, 4), 0, 1, 0x0000_0000, 1),
    "multi-bit-set-64":
        (64, 0x0000_0000, slice(7, 4), 0xF, 0, 0x0000_00F0, 4),
    "multi-bit-clear-64":
        (64, 0x0000_00F0, slice(7, 4), 0x0, 0xF, 0x0000_0000, 4),
    "multi-bit-normal-64":
        (64, 0x0000_0010, slice(7, 4), 0x1, 0x1, 0x0000_0010, 4),
    "multi-bit-reverse-64":
        (64, 0x0000_0010, slice(4, 7), 0x1, 0x8, 0x0000_0080, 4),
    "whole-reg-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(None, None, None),
         0x0FED_CBA9_8765_4321, 0x1234_5678_9ABC_DEF0,
         0x0FED_CBA9_8765_4321, 64),
    "whole-reg-forward-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(None, None, -1),
         0x0FED_CBA9_8765_4321, 0x1234_5678_9ABC_DEF0,
         0x0FED_CBA9_8765_4321, 64),
    "whole-reg-reverse-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(None, None, 1),
         0x1234_5678_9ABC_DEF0, 0x0F7B_3D59_1E6A_2C48,
         0x0F7B_3D59_1E6A_2C48, 64),
    "lower-reg-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(31, None, None),
         0x1234_5678, 0x9ABC_DEF0, 0x1234_5678_1234_5678, 32),
    "lower-reg-forward-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(31, None, -1),
         0x1234_5678, 0x9ABC_DEF0, 0x1234_5678_1234_5678, 32),
    "lower-reg-reverse-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(None, 31, 1),
         0x1234_5678, 0x0F7B_3D59, 0x1234_5678_1e6a_2C48, 32),
    "upper-reg-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(None, 32, None),
         0x9ABC_DEF0, 0x1234_5678, 0x9ABC_DEF0_9ABC_DEF0, 32),
    "upper-reg-forward-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(None, 32, -1),
         0x9ABC_DEF0, 0x1234_5678, 0x9ABC_DEF0_9ABC_DEF0, 32),
    "upper-reg-reverse-64":
        (64, 0x1234_5678_9ABC_DEF0, slice(32, None, 1),
         0x9ABC_DEF0, 0x1E6A_2C48, 0x0F7B_3D59_9ABC_DEF0, 32),
}

ADDRESS = 0x10000


def _create_register(length, debug=False):
    if length == 32:
        buf = np.ndarray((1,), 'u4')
    elif length == 64:
        buf = np.ndarray((1,), 'u8')
    reg = pynq.Register(ADDRESS, length, buffer=buf, debug=debug)
    return reg, buf


@pytest.mark.parametrize('testname', TEST_VECTORS.keys())
def test_register_set_get(testname):
    length, start, idx, update, expected_get, expected_set, count = \
        TEST_VECTORS[testname]
    reg, buf = _create_register(length)
    buf[:] = start
    val = reg[idx]
    assert val == expected_get
    reg[idx] = update
    assert buf[0] == expected_set
    assert str(reg) == hex(expected_set)
    assert int(reg) == expected_set
    assert operator.index(reg) == expected_set
    assert pynq.Register.count(idx, length) == count


test_register_desc = {
    'address_offset': 16,
    'access': 'read-write',
    'size': 32,
    'description': 'Test Register',
    'type': None,
    'id': None,
    'fields': {
         'read-field': {
             'access': 'read-only',
             'bit_offset': 0,
             'bit_width': 4,
             'description': 'Read only field'
         },
         'write-field': {
             'access': 'write-only',
             'bit_offset': 4,
             'bit_width': 4,
             'description': 'Read only field 2'
         },
         'rw-field-1': {
             'access': 'read-write',
             'bit_offset': 8,
             'bit_width': 4,
             'description': 'Read write field 1'
         },
         'rw-field-2': {
             'access': 'read-write',
             'bit_offset': 12,
             'bit_width': 4,
             'description': 'Read write field 1'
         },
         '0-number-field': {
             'access': 'read-write',
             'bit_offset': 16,
             'bit_width': 4,
             'description': 'Field beginning with number'
         },
         'space special !': {
             'access': 'read-write',
             'bit_offset': 20,
             'bit_width': 4,
             'description': 'Field with space and special character'
         },
    }
}

MockRegister = pynq.Register.create_subclass(
    "Test", test_register_desc['fields'], "Test Register Documentation")


@pytest.fixture(params=[32, 64])
def mock_register(request):
    width = request.param
    if width == 32:
        dtype = 'u4'
    elif width == 64:
        dtype = 'u8'
    buf = np.ndarray((1,), dtype)
    buf[0] = 0x87654321
    return MockRegister(ADDRESS, request.param, buffer=buf)


def test_nodoc():
    R = pynq.Register.create_subclass("NoDoc", test_register_desc['fields'])
    assert R.__doc__ is None


@pytest.fixture(params=[32, 64])
def width(request):
    return request.param


def test_reg_readonly(mock_register):
    assert mock_register.read_field == 1
    with pytest.raises(AttributeError):
        mock_register.read_field = 9


def test_reg_writeonly(mock_register):
    assert mock_register.write_field == 2
    mock_register.write_field = 9
    assert int(mock_register) == 0x87654391


NAMED_TESTS = {
    'rw_field_1': (3, 0x87654921),
    'rw_field_2': (4, 0x87659321),
    'r0_number_field': (5, 0x87694321),
    'space_special__': (6, 0x87954321),
}


@pytest.mark.parametrize('register_name', NAMED_TESTS.keys())
def test_reg_readwrite(mock_register, register_name):
    expected_field, expected_reg = NAMED_TESTS[register_name]
    assert getattr(mock_register, register_name) == expected_field
    setattr(mock_register, register_name, 9)
    assert int(mock_register) == expected_reg


INVALID_TESTS = {
    "slice-32":
        (32, slice(0, 31, 2), "Slicing step is not valid."),
    "slice-64":
        (64, slice(0, 31, 2), "Slicing step is not valid."),
    "small-start-32":
        (32, slice(-1, 31), "Slicing endpoint -1 not in range 0 - 31"),
    "small-end-32":
        (32, slice(31, -1), "Slicing endpoint -1 not in range 0 - 31"),
    "large-start-32":
        (32, slice(32, 0), "Slicing endpoint 32 not in range 0 - 31"),
    "large-end-32":
        (32, slice(0, 32), "Slicing endpoint 32 not in range 0 - 31"),
    "invalid-32":
        (32, 1.0, "Index must be int or slice."),
    "small-start-64":
        (64, slice(-1, 63), "Slicing endpoint -1 not in range 0 - 63"),
    "small-end-64":
        (64, slice(63, -1), "Slicing endpoint -1 not in range 0 - 63"),
    "large-start-64":
        (64, slice(64, 0), "Slicing endpoint 64 not in range 0 - 63"),
    "large-end-64":
        (64, slice(0, 64), "Slicing endpoint 64 not in range 0 - 63"),
    "invalid-64":
        (64, 1.0, "Index must be int or slice."),
}


@pytest.mark.parametrize('test_name', INVALID_TESTS.keys())
def test_reg_invalid_read(test_name):
    width, idx, message = INVALID_TESTS[test_name]
    reg, buf = _create_register(width)
    with pytest.raises(ValueError) as excinfo:
        _ = reg[idx]
    assert str(excinfo.value) == message


@pytest.mark.parametrize('test_name', INVALID_TESTS.keys())
def test_reg_invalid_write(test_name):
    width, idx, message = INVALID_TESTS[test_name]
    reg, buf = _create_register(width)
    with pytest.raises(ValueError) as excinfo:
        reg[idx] = 0
    assert str(excinfo.value) == message


def test_reg_large_write():
    reg, buf = _create_register(32)
    with pytest.raises(ValueError) as excinfo:
        reg[1:0] = 4
    assert str(excinfo.value) == "Slicing range cannot represent value 4"


def test_invalid_width():
    buf = np.ndarray((1,), 'u2')
    with pytest.raises(ValueError) as excinfo:
        reg = pynq.Register(ADDRESS, 16, buf)  # NOQA
    assert str(excinfo.value) == "Supported register width is 32 or 64."


def test_init_device(width):
    from .mock_devices import MockMemoryMappedDevice
    device = MockMemoryMappedDevice("test_active_device_" + str(width))
    pynq.Device.active_device = device
    reg = pynq.Register(ADDRESS, width)
    assert (ADDRESS, width // 8) in device.regions
    region = device.regions[(ADDRESS, width // 8)]
    region[0] = 0x12
    assert reg[7:0] == 0x12
    reg[7:0] = 0x34
    assert region[0] == 0x34
    device.close()
    pynq.Device.active_device = None


def test_init_buffer(width):
    buf = bytearray(width // 8)
    reg = pynq.Register(ADDRESS, width, buffer=buf)
    buf[0] = 0x12
    assert reg[7:0] == 0x12
    reg[7:0] = 0x34
    assert buf[0] == 0x34


def test_big_bit(width):
    reg, buf = _create_register(width)
    with pytest.raises(ValueError) as excinfo:
        reg[1] = 2
    assert str(excinfo.value) == "Value to be set should be either 0 or 1."


def test_repr_plain(width):
    reg, buf = _create_register(width)
    buf[0] = 0x1234_5678
    assert "Register(value=305419896)" == repr(reg)


def test_repr_fields(mock_register):
    assert "Register(read_field=1, write_field=2, rw_field_1=3, rw_field_2=4, r0_number_field=5, space_special__=6)" == repr(mock_register)  # NOQA


def test_reg_debug_bit(width, capsys):
    reg, buf = _create_register(width, debug=True)
    reg[4] = 0
    out, err = capsys.readouterr()
    assert out == "Register Debug: Setting bit 4 at address 0x10000 to 0\n"
    _ = reg[1]
    out, err = capsys.readouterr()
    assert out == "Register Debug: Reading index 1 at address 0x10000\n"


def test_reg_debug_slice(width, capsys):
    reg, buf = _create_register(width, debug=True)
    reg[4:6] = 0
    out, err = capsys.readouterr()
    assert out == "Register Debug: Setting bits 6:4 at address 0x10000 to 0\n"
    # assert out == "Register Debug: Setting bits 4:6 at address 0x10000 to 0\n"  # NOQA
    # assert out == "Register Debug: Setting bits 7:4 at address 0x10000 to 0\n"  # NOQA
    _ = reg[1:3]
    out, err = capsys.readouterr()
    # assert out == "Register Debug: Reading bits 1:3 at address 0x10000\n"
    assert out == "Register Debug: Reading bits 3:1 at address 0x10000\n"


def test_blank_regmap():
    buf = bytearray(16)
    with pytest.raises(RuntimeError) as excinfo:
        rm = pynq.registers.RegisterMap(buf)  # NOQA
    assert str(excinfo.value) == \
           "Only subclasses of RegisterMap from create_subclass can be instantiated"  # NOQA


test_registermap_desc = {
    'test_register': test_register_desc,
    'out-of-order': {
        'address_offset': 80,
        'access': 'read-write',
        'size': 32,
        'description': 'Out of order register'
    },
    'aligned_4': {
        'address_offset': 32,
        'access': 'read-write',
        'size': 32,
        'description': 'Aligned 32-bit register'
    },
    'aligned_8': {
        'address_offset': 40,
        'access': 'read-write',
        'size': 64,
        'description': 'Aligned 64-bit register'
    },
    'unaligned_8': {
        'address_offset': 52,
        'access': 'read-write',
        'size': 64,
        'description': 'Unaligned 64-bit register'
    },
    'read-only': {
        'address_offset': 64,
        'access': 'read-only',
        'size': 32,
        'description': 'Read only 32-bit register'
    },
    'write-only': {
        'address_offset': 68,
        'access': 'write-only',
        'size': 32,
        'description': 'Write-only 32-bit register'
    },
    'space special !': {
        'address_offset': 72,
        'access': 'read-write',
        'size': 32,
        'description': 'Badly named 32-bit register'
    },
    '001_numbered': {
        'address_offset': 76,
        'access': 'read-write',
        'size': 32,
        'description': 'Badly named 32-bit register'
    },
}

MockRegisterMap = pynq.registers.RegisterMap.create_subclass(
    "Mock", test_registermap_desc)


@pytest.fixture(params=['bytearray', 'ndarray'])
def mock_registermap(request):
    if request.param == 'bytearray':
        buf = bytearray(96)
    elif request.param == 'ndarray':
        buf = np.ndarray((96,), 'u1')
    buf[16:20] = memoryview(b'\x21\x43\x65\x87')
    rm = MockRegisterMap(buf)
    return rm, buf


@pytest.mark.parametrize('register_name', NAMED_TESTS.keys())
def test_regmap_fields(mock_registermap, register_name):
    expected_field, expected_reg = NAMED_TESTS[register_name]
    rm, buf = mock_registermap

    assert getattr(rm.test_register, register_name) == expected_field
    setattr(rm.test_register, register_name, 9)
    assert struct.unpack('I', buf[16:20])[0] == expected_reg


REGMAP_TESTS = {
    'aligned_4': (32, 'I', 0x12345678, 0x87654321),
    'aligned_8': (40, 'Q', 0x123456789ABCDEF0, 0x0FEDCBA987654321),
    'unaligned_8': (52, 'Q', 0x123456789ABCDEF0, 0x0FEDCBA987654321),
    'write_only': (68, 'I', 0x12345678, 0x87654321),
    'space_special__': (72, 'I', 0x12345678, 0x87654321),
    'r001_numbered': (76, 'I', 0x12345678, 0x87654321),
    'out_of_order': (80, 'I', 0x123456, 0x876543),
}


@pytest.mark.parametrize('register_name', REGMAP_TESTS.keys())
def test_regmap_rw(mock_registermap, register_name):
    offset, struct_string, start, end = REGMAP_TESTS[register_name]
    rm, buf = mock_registermap

    width = struct.calcsize(struct_string)
    buf[offset:offset+width] = memoryview(struct.pack(struct_string, start))
    assert getattr(rm, register_name)[:] == start
    setattr(rm, register_name, end)
    assert struct.unpack(struct_string, buf[offset:offset+width])[0] == end


@pytest.mark.parametrize('register_name', REGMAP_TESTS.keys())
def test_regmap_rw_mmio(register_name):
    from .mock_devices import MockRegisterDevice
    device = MockRegisterDevice('test_regmap_rw_mmio')
    mmio = pynq.MMIO(ADDRESS, 128, device=device)
    rm = MockRegisterMap(mmio.array)
    offset, struct_string, start, end = REGMAP_TESTS[register_name]
    read_transaction = (ADDRESS+offset, struct.pack(struct_string, start))
    write_transaction = (ADDRESS+offset, struct.pack(struct_string, end))
    with device.check_transactions([read_transaction], []):
        value = getattr(rm, register_name)[:]
        assert value == start
    with device.check_transactions([], [write_transaction]):
        setattr(rm, register_name, end)
    device.close()


def test_regmap_read_only(mock_registermap):
    rm, buf = mock_registermap
    buf[64:68] = [0x21, 0x43, 0x65, 0x87]
    assert int(rm.read_only) == 0x87654321
    with pytest.raises(AttributeError):
        rm.read_only = 0x12345678


expected_regmap_repr = """RegisterMap {
  test_register = Register(read_field=0, write_field=1, rw_field_1=1, rw_field_2=1, r0_number_field=2, space_special__=1),
  aligned_4 = Register(value=589439264),
  aligned_8 = Register(value=3399704436437297448),
  unaligned_8 = Register(value=4267786510494217524),
  read_only = Register(value=1128415552),
  write_only = Register(value=1195787588),
  space_special__ = Register(value=1263159624),
  r001_numbered = Register(value=1330531660),
  out_of_order = Register(value=1397903696)
}"""  # NOQA


def test_regmap_repr(mock_registermap):
    rm, buf = mock_registermap
    buf[:] = range(96)
    print(repr(rm))
    assert expected_regmap_repr == repr(rm)


bad_size_register_desc = {
    'too_long': {
        'address_offset': 0,
        'access': 'read-write',
        'size': 128,
        'description': 'Aligned 128-bit register'
    },
}


def test_too_long():
    RegClass = pynq.registers.RegisterMap.create_subclass(
         "TooLong", bad_size_register_desc)
    buf = bytearray(16)
    with pytest.warns(UserWarning):
        RegClass(buf)
