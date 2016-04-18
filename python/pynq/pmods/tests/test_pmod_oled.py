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
from pynq import Overlay
from pynq.pmods.pmod_oled import PMOD_OLED
from pynq.test.util import user_answer_yes

flag = user_answer_yes("\nPMOD OLED attached to the board?")
if flag:
    global oled_id
    oled_id = int(input("Type in the PMOD ID of the OLED (1 ~ 4): "))

@pytest.mark.run(order=24)
@pytest.mark.skipif(not flag, reason="need OLED attached in order to run")
def test_write_string1():
    """Test for the OLED PMOD.
    
    Writes on the OLED the string 'Welcome to Zybo.' and asks the user to 
    confirm if it is shown on the OLED. After that, it clears the screen. 
    This test is done on the PMOD overlay, and can be skipped.
    
    """
    global oled
    oled = PMOD_OLED(oled_id)
    
    oled.write('Welcome to Zybo.')
    assert user_answer_yes("\nWelcome message shown on the OLED?")
    oled.clear()
    assert user_answer_yes("OLED screen clear now?")      
    
    del oled
    
@pytest.mark.run(order=39)
def test_write_string2():
    """Test for the OLED PMOD.
    
    Writes on the OLED the string 'Welcome to Zybo.' and asks the user to 
    confirm if it is shown on the OLED. After that, it clears the screen. 
    This test is done on the audiovideo overlay, and is required.
    
    """
    input("\nPress enter after plugging the PMOD OLED into PMOD 2 (JC).")
    oled = PMOD_OLED(2)
    
    oled.write('Welcome to Zybo.')
    assert user_answer_yes("Welcome message shown on the OLED?")
    oled.clear()
    assert user_answer_yes("OLED screen clear now?")      
    
    del oled
    