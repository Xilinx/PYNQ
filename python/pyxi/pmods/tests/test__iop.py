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
__email__       = "xpp_support@xilinx.com"


import pytest
from pyxi import Overlay
from pyxi.pmods._iop import request_iop

global ol
ol = Overlay("pmod.bit")

@pytest.mark.run(order=10)
def test_request_iop_conflicting():
    """Test for the _IOP class and the method request_iop().
    
    Creates multiple IOP instances on the same fixed ID. Tests whether 
    request_iop() correctly raises a LookupError exception.
    
    """
    ol.flush_iop_dictionary()
    
    fixed_id = 1
    request_iop(fixed_id,'adc.bin')
    pytest.raises(LookupError, request_iop, fixed_id, 'dac.bin')
    
    ol.flush_iop_dictionary()

@pytest.mark.run(order=11)
def test_request_iop_sameobject():
    """Test for the _IOP class and the method request_iop().
    
    Even with the *force* flag to be False, the request_iop() should not raise 
    any exception since the previous IOP runs the same program.
    
    """
    ol.flush_iop_dictionary()
    
    fixed_id = 1
    request_iop(fixed_id)
    exception_raised = False
    try:
        request_iop(fixed_id)
    except LookupError:
        exception_raised = True
    assert not exception_raised, 'Method request_iop() not working properly.'
    
    ol.flush_iop_dictionary()

@pytest.mark.run(order=12)
def test_request_iop_force():
    """Test for the _IOP class and the method request_iop().
    
    Creates multiple IOP instances on the same fixed ID with the *force* 
    flag active. Tests whether request_iop() behaves correctly, silently 
    overwriting the old IOP instance.
    
    """
    ol.flush_iop_dictionary()
    
    exception_raised = False
    fixed_id = 1
    try:
        request_iop(fixed_id, force=True)
        request_iop(fixed_id, force=True)
    except LookupError:
        exception_raised = True
    assert not exception_raised, 'Flag *force* not working properly.'
    
    ol.flush_iop_dictionary()
