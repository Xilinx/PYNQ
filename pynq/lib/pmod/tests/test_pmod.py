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


import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB


__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


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
