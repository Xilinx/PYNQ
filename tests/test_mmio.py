#   Copyright (c) 2022, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import numpy as np
import pynq
import pytest
import struct
import warnings

__author__ = "Peter Ogden, Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


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
    (300, np.uint32(53970361), int(53970361).to_bytes(4, 'little')),
    (256, -14921033, int(np.uint32(-14921033)).to_bytes(4, 'little'))
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


def test_unsupported_length_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.read(4, 6)
    assert str(excinfo.value) == \
        "MMIO currently only supports 1, 2, 4 and 8-byte reads."


def test_bad_endianness_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        mmio.read(4, 8, word_order='middle')
    assert str(excinfo.value) == \
        "MMIO only supports big and little endian."


def test_oob_write(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.write(ADDR_RANGE, 1234)


def test_oob_read(device):
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(IndexError):
        mmio.read(ADDR_RANGE)


def test_active_device_4byte_read(register_device):
    device = register_device
    pynq.Device.active_device = device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE)
    testdata = struct.pack('I', 0x12345678)
    with device.check_transactions([TEST_READ_DATA[0]], []):
        read = mmio.read(4)
    assert read == 0x12345678
    assert mmio.device == device
    pynq.Device.active_device = None


def test_active_device_2byte_read(register_device):
    device = register_device
    pynq.Device.active_device = device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE)
    with device.check_transactions([TEST_READ_DATA[0]], []):
        read = mmio.read(4, 2)
    assert read == 0x5678
    assert mmio.device == device
    pynq.Device.active_device = None


def test_active_device_1byte_read(register_device):
    device = register_device
    pynq.Device.active_device = device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE)
    with device.check_transactions([TEST_READ_DATA[0]], []):
        read = mmio.read(4, 1)
    assert read == 0x78
    assert mmio.device == device
    pynq.Device.active_device = None


def test_8byte_littleendian_read(register_device):
    device = register_device
    pynq.Device.active_device = device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE)
    with device.check_transactions(TEST_READ_DATA, []):
        read = mmio.read(4, 8, word_order='little')
    assert read == 0xbeefcafe12345678
    assert mmio.device == device
    pynq.Device.active_device = None


def test_8byte_bigendian_read(register_device):
    device = register_device
    pynq.Device.active_device = device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE)
    with device.check_transactions(TEST_READ_DATA, []):
        read = mmio.read(4, 8, word_order='big')
    assert read == 0x12345678beefcafe
    assert mmio.device == device
    pynq.Device.active_device = None


def test_mmap_bad_length_write(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(MemoryError) as excinfo:
        mmio.write(4, bytes(range(6)))
    assert str(excinfo.value) == \
        "Unaligned write: data length must be multiple of 4."


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


@pytest.mark.parametrize('transaction', TEST_DATA_NUMPY)
def test_reg_write_np_uint32(transaction, register_device):
    offset, pyobj, bytesobj = transaction
    device = register_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with device.check_transactions([], [(BASE_ADDRESS+offset, bytesobj)]):
        mmio.write(offset, pyobj)


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
    offset, testdata = (956, 102.687)
    mmio.write(offset, np.single(testdata))
    read = mmio.read(offset, data_type='float')
    assert np.isclose(read, testdata, rtol=1e-05, atol=1e-08, equal_nan=False)


def test_reg_read_float_len8(mmap_device):
    device = mmap_device
    mmio = pynq.MMIO(BASE_ADDRESS, ADDR_RANGE, device=device)
    with pytest.raises(ValueError) as excinfo:
        read = mmio.read(4, 8, data_type='float')
    assert str(excinfo.value) == \
        "reading floating point is only valid when length is equal to 4"
