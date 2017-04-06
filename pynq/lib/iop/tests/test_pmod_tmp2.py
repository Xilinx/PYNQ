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

__author__      = "Naveen Purushotham, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import pytest
from pynq import Overlay
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import Pmod_TMP2
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_pmod_id

flag = user_answer_yes("\nPmod TMP2 attached to the board?")
if flag:
    global tmp2_id
    
    pmod_id = get_pmod_id('Pmod TMP2')
    if pmod_id == 'A':
        tmp2_id = PMODA
    elif pmod_id == 'B':
        tmp2_id = PMODB
    else:
        raise ValueError("Please type in A or B.")

@pytest.mark.run(order=28)
@pytest.mark.skipif(not flag, reason="need TMP2 attached in order to run")
def test_readtemp():
    """Test for the TMP2 class.
    
    Reads the TMP2 and asks the user if the temperature is displayed.
    
    """
    global tmp2
    tmp2 = Pmod_TMP2(tmp2_id)
    n = tmp2.read()
    print("\nCurrent temperature: {} C.".format(n))
    assert user_answer_yes("Reading in celsius displayed?")
    
    del tmp2
    