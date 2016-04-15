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


from random import randint
from time import sleep
import pytest
from pynq import Overlay
from pynq.pmods.pmod_adc import PMOD_ADC
from pynq.pmods.pmod_dac import PMOD_DAC
from pynq.test.util import user_answer_yes

flag = user_answer_yes("\nPMOD ADC and PMOD DAC attached (straight cable)?")
if flag:
        global adc_id, dac_id
        dac_id = int(input("Type in the PMOD ID of the DAC (1 ~ 4): "))
        adc_id = int(input("Type in the PMOD ID of the ADC (1 ~ 4): "))

@pytest.mark.run(order=25) 
@pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")
def test_loop_single():
    """Test for writing a single value via the loop.
    
    First check whether read() correctly returns a string. Then ask the users 
    to write a voltage on the DAC, read from the ADC, and compares the two 
    voltages.
    
    Note
    ----
    Users can use a straight cable (instead of wires) to do this test.
    For the 6-pin DAC PMOD, it has to be plugged into the upper row of the PMOD
    interface.
    
    """
    global dac,adc
    dac = PMOD_DAC(dac_id)
    adc = PMOD_ADC(adc_id)
    
    value = float(input("\nInsert a voltage in the range of [0.00, 2.00]: "))
    assert value<=2.00, 'Input voltage should not be higher than 2.00V.'
    assert value>=0.00, 'Input voltage should not be lower than 0.00V.'
    dac.write(value)
    assert abs(value-float(adc.read()))<0.06, 'Read value != write value.'

@pytest.mark.run(order=26) 
@pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")
def test_loop_random():
    """Test for writing multiple random values via the loop.
    
    This test writes a sequence of voltages on the DAC and read from the ADC, 
    then checks whether they are approximately the same (with a delta of .06).
    
    Note
    ----
    Users can use a straight cable (instead of wires) to do this test.
    For the 6-pin DAC PMOD, it has to be plugged into the upper row of the PMOD
    interface.
    
    """
    print('\nGenerating 100 random voltages from 0.00V to 2.00V...')
    global dac,adc
    
    for i in range(100):
        value = 0.01*randint(0,200)
        dac.write(value)
        sleep(0.001)
        assert abs(value-float(adc.read()))<0.06, \
            'Read value {} != write value {}.'.format(adc.read(), value)
    
    del dac,adc
