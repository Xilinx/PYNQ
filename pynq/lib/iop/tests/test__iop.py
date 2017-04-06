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

__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import pytest
from pynq import Overlay
from pynq.iop import request_iop

global ol
ol = Overlay("base.bit")

@pytest.mark.run(order=11)
def test_request_iop():
    """Test for the _IOP class and the method request_iop().
    
    Test whether the request_iop() can return an object without errors. 
    This is a test for case 1 (for more information, please see request_iop).
    
    """
    fixed_id = 1
    exception_raised = False
    try:
        request_iop(fixed_id,'mailbox.bin')
    except LookupError:
        exception_raised = True
    assert not exception_raised, 'request_iop() should not raise exception.'
    
    ol.reset()
    
@pytest.mark.run(order=12)
def test_request_iop_same():
    """Test for the _IOP class and the method request_iop().
    
    The request_iop() should not raise any exception since the previous IOP 
    runs the same program.
    This is a test for case 1 (for more information, please see request_iop).
    
    """
    fixed_id = 1
    exception_raised = False
    request_iop(fixed_id,'mailbox.bin')
    try:
        request_iop(fixed_id,'mailbox.bin')
    except LookupError:
        exception_raised = True
    assert not exception_raised, 'request_iop() should not raise exception.'
    
    ol.reset()
    
@pytest.mark.run(order=13)
def test_request_iop_conflict():
    """Test for the _IOP class and the method request_iop().
    
    Creates multiple IOP instances on the same fixed ID. Tests whether 
    request_iop() correctly raises a LookupError exception.
    This is a test for case 2 (for more information, please see request_iop).
    
    """
    fixed_id = 1
    request_iop(fixed_id,'pmod_adc.bin')
    pytest.raises(LookupError, request_iop, fixed_id, 'pmod_dac.bin')
    
    ol.reset()
    

