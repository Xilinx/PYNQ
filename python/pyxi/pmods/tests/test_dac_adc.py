"""Test module for adc.py and dac.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


import pytest
from random import randint
from time import sleep
from pyxi.pmods.adc import ADC
from pyxi.pmods.dac import DAC
from pyxi.pmods._iop import _flush_iops
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nBoth ADC and DAC attached (straight cable)?")
if flag:
        global adc_id, dac_id
        dac_id = int(input("Type in the PMOD ID of the DAC (1 ~ 4): "))
        adc_id = int(input("Type in the PMOD ID of the ADC (1 ~ 4): "))
    
@pytest.mark.run(order=25)  
@pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")
def test_adc_value():
    """Tests whether value() correctly returns a number."""
    global dac,adc
    dac = DAC(dac_id)
    adc = ADC(adc_id)
    assert type(adc.value()) is int

@pytest.mark.run(order=26) 
@pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")
def test_adc_read():
    """Tests whether read() correctly returns a string."""  
    assert type(adc.read()) is str

@pytest.mark.run(order=27) 
@pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")
def test_loop_single():
    """Asks the user to write a voltage on the DAC, read from the ADC,
    and compares the two voltages
    """
    value = float(input("\nInsert a voltage to write (0.0 - 1.2): "))
    assert value<=1.20, 'Input voltage higher than 1.20V.'
    assert value>=0.00, 'Input voltage lower than 0.00V.'
    dac.write(value)
    assert abs(value-float(adc.read()))<0.06

@pytest.mark.run(order=28) 
@pytest.mark.skipif(not flag, reason="need both ADC and DAC attached")
def test_loop_random():
    """Writes a sequence of voltages on the DAC and read from the ADC, 
    then checks that they are approximatively the same 
    (with a delta of .05).
    """
    print('\nGenerating 100 random voltages from 0.00V to 1.20V...')
    DelaySec = 0.001
    for i in range(0,100):
        value = 0.01*randint(0,120)
        dac.write(value)
        sleep(DelaySec)
        assert abs(value-float(adc.read()))<0.06
    _flush_iops()
