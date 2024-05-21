#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from random import randint
from time import sleep
import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod_ADC
from pynq.lib.pmod import Pmod_DAC
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_interface_id




try:
    _ = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nPmod ADC and DAC attached (straight cable)?")
if flag1:
    dac_id = eval(get_interface_id('Pmod DAC', options=['PMODA', 'PMODB']))
    adc_id = eval(get_interface_id('Pmod ADC', options=['PMODA', 'PMODB']))
flag = flag0 and flag1


@pytest.mark.skipif(not flag, 
                    reason="need ADC and DAC attached to the base overlay")
def test_dac_adc_loop():
    """Test for writing a single value via the loop.
    
    First check whether read() correctly returns a string. Then ask the users 
    to write a voltage on the DAC, read from the ADC, and compares the two 
    voltages.
    
    The exception is raised when the difference is more than 10% and more than
    0.1V.
    
    The second test writes a sequence of voltages on the DAC and read from 
    the ADC, then checks whether they are approximately the same 
    (with a delta of 10%).

    Note
    ----
    Users can use a straight cable (instead of wires) to do this test.
    For the 6-pin DAC Pmod, it has to be plugged into the upper row of the 
    Pmod interface.
    
    """
    Overlay('base.bit').download()
    dac = Pmod_DAC(dac_id)
    adc = Pmod_ADC(adc_id)

    value = float(input("\nInsert a voltage in the range of [0.00, 2.00]: "))
    assert value <= 2.00, 'Input voltage should not be higher than 2.00V.'
    assert value >= 0.00, 'Input voltage should not be lower than 0.00V.'
    dac.write(value)
    sleep(0.05)
    assert round(abs(value-adc.read()[0]), 2) < max(0.1, 0.1*value), \
        'Read value != write value.'

    print('Generating 100 random voltages from 0.00V to 2.00V...')
    for _ in range(100):
        value = round(0.0001*randint(0, 20000), 4)
        dac.write(value)
        sleep(0.05)
        assert round(abs(value-adc.read()[0]), 2) < max(0.1, 0.1*value), \
            'Read value {} != write value {}.'.format(adc.read(), value)

    del dac, adc


