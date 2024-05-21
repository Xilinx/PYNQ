#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pytest
from pynq import Overlay
from pynq.lib.arduino import Arduino
from pynq.lib.arduino import ARDUINO




try:
    _ = Overlay('base.bit', download=False)
    flag = True
except IOError:
    flag = False


@pytest.mark.skipif(not flag, reason="need base overlay to run")
def test_arduino_microblaze():
    """Test for the Arduino class.

    There are 3 tests done here:

    1. Test whether `Arduino()` can return an object without errors. 

    2. Calling `Arduino()` should not raise any exception if the previous 
    Arduino object runs the same program.

    3. Creates multiple Arduino instances on the same fixed ID. Exception 
    should be raised in this case.
    
    """
    ol = Overlay('base.bit')

    for mb_info in [ARDUINO]:
        exception_raised = False
        try:
            _ = Arduino(mb_info, 'arduino_mailbox.bin')
        except RuntimeError:
            exception_raised = True
        assert not exception_raised, 'Should not raise exception.'
        ol.reset()

        exception_raised = False
        _ = Arduino(mb_info, 'arduino_mailbox.bin')
        try:
            _ = Arduino(mb_info, 'arduino_mailbox.bin')
        except RuntimeError:
            exception_raised = True
        assert not exception_raised, 'Should not raise exception.'
        ol.reset()

        exception_raised = False
        _ = Arduino(mb_info, 'arduino_analog.bin')
        try:
            _ = Arduino(mb_info, 'arduino_lcd18.bin')
        except RuntimeError:
            exception_raised = True
        assert exception_raised, 'Should raise exception.'
        ol.reset()

    del ol


