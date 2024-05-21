#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB




try:
    _ = Overlay('base.bit', download=False)
    flag = True
except IOError:
    flag = False


@pytest.mark.skipif(not flag, reason="need base overlay to run")
def test_pmod_microblaze():
    """Test for the Pmod class.

    There are 3 tests done here:

    1. Test whether `Pmod()` can return an object without errors. 

    2. Calling `Pmod()` should not raise any exception if the previous Pmod
    object runs the same program.

    3. Creates multiple Pmod instances on the same fixed ID. Exception should
    be raised in this case.
    
    """
    ol = Overlay('base.bit')

    for mb_info in [PMODA, PMODB]:
        exception_raised = False
        try:
            _ = Pmod(mb_info, 'pmod_mailbox.bin')
        except RuntimeError:
            exception_raised = True
        assert not exception_raised, 'Should not raise exception.'
        ol.reset()

        exception_raised = False
        _ = Pmod(mb_info, 'pmod_mailbox.bin')
        try:
            _ = Pmod(mb_info, 'pmod_mailbox.bin')
        except RuntimeError:
            exception_raised = True
        assert not exception_raised, 'Should not raise exception.'
        ol.reset()

        exception_raised = False
        _ = Pmod(mb_info, 'pmod_dac.bin')
        try:
            _ = Pmod(mb_info, 'pmod_adc.bin')
        except RuntimeError:
            exception_raised = True
        assert exception_raised, 'Should raise exception.'
        ol.reset()

    del ol


