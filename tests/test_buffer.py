import pynq
import pytest

import numpy as np

from .mock_devices import MockAllocateDevice


BUFFER_ADDRESS = 0x10000


@pytest.fixture
def device():
    device = MockAllocateDevice('buffer_device')
    yield device
    device.check_allocated()
    device.close()


def test_lifetime_check(device):
    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        buf = pynq.allocate((1024, 1024), 'u4', target=device)  # NOQA
    with pytest.raises(AssertionError):
        device.check_allocated()


def test_allocate(device):
    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        buf = pynq.allocate((1024, 1024), 'u4', target=device)
    assert buf.device_address == BUFFER_ADDRESS
    assert buf.physical_address == BUFFER_ADDRESS
    assert buf.bo == 10
    assert buf.coherent is False
    assert buf.cacheable is True

# Test format
# 1. shape
# 2. dtype
# 3. idxes
# 4. expected offset
# 5. expected length


OFFSET_TESTS = {
    'whole-test': ((1024,), 'u4', tuple(), 0, 4096),
    'dim1_test': ((1024, 1024), 'u4', (1,), 4096, 4096),
    'dim2_test': ((1024, 1024), 'u4', (1, slice(512, None)), 6144, 2048),
    'np-dtype': ((1024,), np.uint32, (slice(None, None, None),), 0, 4096),
}


@pytest.mark.parametrize('testname', OFFSET_TESTS.keys())
def test_slices(device, testname):
    shape, dtype, idxes, exp_offset, exp_length = OFFSET_TESTS[testname]

    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        buf = pynq.allocate(shape, dtype, target=device)

    subbuf = buf
    for idx in idxes:
        subbuf = subbuf[idx]
    assert subbuf.coherent is False
    assert subbuf.cacheable is True
    assert subbuf.bo == 10
    assert subbuf.device_address == BUFFER_ADDRESS + exp_offset
    assert subbuf.physical_address == BUFFER_ADDRESS + exp_offset

    with device.check_memops(flushes=[(10, exp_offset, exp_length)]):
        subbuf.flush()
    with device.check_memops(flushes=[(10, exp_offset, exp_length)]):
        subbuf.sync_to_device()

    with device.check_memops(invalidates=[(10, exp_offset, exp_length)]):
        subbuf.invalidate()
    with device.check_memops(invalidates=[(10, exp_offset, exp_length)]):
        subbuf.sync_from_device()


@pytest.mark.parametrize('testname', OFFSET_TESTS.keys())
def test_slices_coherent(device, testname):
    shape, dtype, idxes, exp_offset, exp_length = OFFSET_TESTS[testname]

    with device.check_memops(allocates=[(10, True, BUFFER_ADDRESS)]):
        buf = pynq.allocate(shape, dtype, target=device)

    subbuf = buf
    for idx in idxes:
        subbuf = subbuf[idx]
    assert subbuf.coherent is True
    assert subbuf.cacheable is False
    assert subbuf.bo == 10
    assert subbuf.device_address == BUFFER_ADDRESS + exp_offset
    assert subbuf.physical_address == BUFFER_ADDRESS + exp_offset

    with device.check_memops():
        subbuf.flush()
        subbuf.sync_to_device()
        subbuf.invalidate()
        subbuf.sync_from_device()


class MockCache:
    def __init__(self):
        self.returns = []

    def return_pointer(self, obj):
        self.returns.append(obj)


def _autofree_scope(device, cache):
    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        buf = pynq.allocate((1024, 1024), 'u4', target=device)
    buf.pointer = 4321
    buf.return_to = cache


def test_autofree(device):
    cache = MockCache()
    _autofree_scope(device, cache)
    assert cache.returns == [4321]


def test_withfree(device):
    cache = MockCache()
    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        with pynq.allocate((1024, 1024), 'u4', target=device) as buf:
            buf.pointer = 1234
            buf.return_to = cache
        assert cache.returns == [1234]


def test_free_nocache(device):
    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        with pynq.allocate((1024, 1024), 'u4', target=device) as buf:
            buf.return_to = None
            buf.pointer = 1234


def test_close_deprecation(device):
    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        buf = device.allocate((1024,), 'u4')
    with pytest.warns(DeprecationWarning):
        buf.close()


def test_default(device):
    pynq.Device.active_device = device
    with device.check_memops(allocates=[(10, False, BUFFER_ADDRESS)]):
        buf = pynq.allocate((1024, 1024), 'u4')
    assert buf.device_address == BUFFER_ADDRESS
    assert buf.physical_address == BUFFER_ADDRESS
    assert buf.bo == 10
    assert buf.coherent is False
    assert buf.cacheable is True
    pynq.Device.active_device = None
