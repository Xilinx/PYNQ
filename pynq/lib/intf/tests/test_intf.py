#   Copyright (c) 2016, Xilinx, Inc.
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


from random import randint
import numpy as np
import pytest
from pynq import Overlay
from pynq.lib.intf import Intf
from pynq.lib.intf import ARDUINO
from pynq.lib.intf import MAILBOX_OFFSET


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    _ = Overlay('interface.bit')
    flag = True
except IOError:
    flag = False


@pytest.mark.skipif(not flag, reason="need interface overlay to run")
def test_intf():
    """Test for interface Microblaze processor.

    First test whether Intf() can return an object without errors.

    Then no exception should raise when the previous processor
    runs the same program.

    Finally test multiple functions / attributes of the instance of Intf().

    """
    ol = Overlay('interface.bit')
    ol.download()

    # Test Intf() initialization
    exception_raised = False
    try:
        _ = Intf(ARDUINO, 'arduino_intf.bin')
    except RuntimeError:
        exception_raised = True
    assert not exception_raised, 'Intf() should not raise exception.'
    ol.reset()

    exception_raised = False
    _ = Intf(ARDUINO, 'arduino_intf.bin')
    try:
        _ = Intf(ARDUINO, 'arduino_intf.bin')
    except RuntimeError:
        exception_raised = True
    assert not exception_raised, 'Intf() should not raise exception.'
    ol.reset()

    # Test whether control parameters can be written into the mailbox
    intf = Intf(ARDUINO, 'arduino_intf.bin')
    data_write = list()
    for i in range(10):
        data_write.append(randint(0, pow(2, 32) - 1))

    intf.write_control(data_write)
    for index in range(10):
        data_read = intf.read(MAILBOX_OFFSET + 4 * index)
        assert data_write[index] == data_read, \
            f'Mailbox location {index} read {data_read} != write {data_write}.'

    # Test the capability to allocate buffers
    num_samples = 100
    test_data_32_addr = intf.allocate_buffer('test_data_32_buf',
                                             num_samples,
                                             data_type='unsigned int')
    test_data_64_addr = intf.allocate_buffer('test_data_64_buf',
                                             num_samples,
                                             data_type='unsigned long long')
    assert test_data_32_addr is not None, 'Failed to allocate memory.'
    assert test_data_64_addr is not None, 'Failed to allocate memory.'

    # Test writing and reading the data
    data_32_write = np.random.randint(0, 2**32, num_samples, dtype=np.uint32)
    data_64_write = np.random.randint(0, 2**64, num_samples, dtype=np.uint64)
    for index in range(num_samples):
        intf.buffers['test_data_32_buf'][index] = data_32_write[index]
        intf.buffers['test_data_64_buf'][index] = data_64_write[index]

    data_32_read = intf.ndarray_from_buffer(
        'test_data_32_buf', num_samples * 4, dtype=np.uint32)
    data_64_read = intf.ndarray_from_buffer(
        'test_data_64_buf', num_samples * 8, dtype=np.uint64)

    assert np.array_equal(data_32_read, data_32_write), \
        'Reading wrong numpy uint32 data.'
    assert np.array_equal(data_64_read, data_64_write), \
        'Reading wrong numpy uint64 data.'

    # Resetting the buffers
    del data_32_read, data_32_write, data_64_read, data_64_write
    intf.reset_buffers()
    assert len(intf.buffers) == 0, \
        'Buffers are not empty after resetting.'
    ol.reset()
