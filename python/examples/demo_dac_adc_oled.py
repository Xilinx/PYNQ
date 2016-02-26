"""Demo for ADC + DAC + OLED."""

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"

from pyxi.board.utils import delay
from pyxi.pmods.adc import ADC
from pyxi.pmods.dac import DAC
from pyxi.pmods.oled import OLED

def demo_dac_adc_oled():
    """Demo of the DAC-ADC-OLED Loopback."""
    
    print('Make sure ADC, DAC and OLED are attached to the board.')
    
    global adc, dac, oled
    dac = DAC(int(input("Type in the PMOD's ID of the DAC (1 ~ 4): ")))
    adc = ADC(int(input("Type in the PMOD's ID of the ADC (1 ~ 4): ")))
    oled = OLED(int(input("Type in the PMOD's ID of the OLED (1 ~ 4): ")))
    
    """Repeatedly write values to the DAC, read them from the ADC
    and prints the results on the OLED
    """         
    print("\nWriting values from 0.0V to 1.2V with step 0.1V.")
    print("This is done twice. Look at the OLED...")
    
    DelaySec = 0.3
    for i in range(0, 2):
        for j in range(0, 13):
            value = 0.1 * j
            dac.write(value)
            delay(DelaySec)
            oled.write(adc.read())
            
    print('End of this demo ...')   
                              
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()

if __name__ == "__main__":
    demo_dac_adc_oled()