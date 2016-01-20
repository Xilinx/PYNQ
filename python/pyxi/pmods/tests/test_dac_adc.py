"""Test module for adc.py and dac.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.tests.random import rng
from pyxi.board.utils import delay

from pyxi.pmods.adc import ADC
from pyxi.pmods.dac import DAC

adc = None
dac = None

class Test_0_ADC(unittest.TestCase):
    """TestCase for the ADC class."""

    def test_0_value(self):
        """Tests whether value() correctly returns a number."""
        self.assertIs(type(adc.value()), int)     

    def test_1_value(self):
        """Tests whether read() correctly returns a string."""  
        self.assertIs(type(adc.read()), str)    


class TestDAC_1_ADC(unittest.TestCase):
    """TestCase for both the DAC and ADC classes."""

    def test_0_single(self):
        """Asks the user to write a voltage on the DAC, read from the ADC,
        and compares the two voltages
        """         
        value = float(input("\nInsert a voltage to write (0.0 - 1.2): "))
        self.assertTrue(value<=1.20, 'Input voltage higher than 1.20V.')
        self.assertTrue(value>=0.00, 'Input voltage lower than 0.00V.')
        dac.write(value)
        self.assertAlmostEqual(value, float(adc.read()), delta=.06)
    
    def test_1_random(self):
        """Writes a sequence of voltages on the DAC and read from the ADC, 
        then checks that they are approximatively the same 
        (with a delta of .05).
        """
        print('\nGenerating 100 random voltages from 0.00V to 1.20V...')
        DelaySec = 0.01
        for i in range(0,100):
            value = 0.01*(rng()%121)
            dac.write(value)
            delay(DelaySec)
            self.assertAlmostEqual(value, float(adc.read()), delta=.06)

def test_dac_adc():
    if not unittest.request_user_confirmation(
            'Are both ADC and DAC attached to the board?'):
        raise unittest.SkipTest()

    global adc, dac
    dac = DAC(int(input("Type in the PMOD's ID of the DAC (1 ~ 4): ")))
    adc = ADC(int(input("Type in the PMOD's ID of the ADC (1 ~ 4): ")))

    # starting tests
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()


if __name__ == "__main__":
    test_dac_adc()
