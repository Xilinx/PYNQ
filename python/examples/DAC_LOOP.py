
def dac_loop(DAC_Port=2, ADC_Port=1, OLED_Port=3, switch_nmbr=0, delay_secs=1):
    '''DAC writes -> ADC reads -> OLED displays, from 0.1V to 1V  in 0.1V steps

    Arguments
    ---------
    DAC_Port (int)       : Any unused PMod port, 1-4, on Zybo
    ADC_Port (int)       : Any unused PMod port, 1-4, on Zybo
    OLED_Port (int)      : Any unused PMod port, 1-4, on Zybo
    switch_nmbr (int)    : Any one of slide-switches, 0-3, on Zybo
    delay_secs (float)   : +ve delay < 2 seconds max
    
    '''
    # Import PMOD classes from library PythonXilinx (pyxi.pmods)
    from pyxi.pmods import OLED, ADC, DAC
    
    from pyxi.board import  LED, Switch
    from pyxi.board.utils import delay
    
    # Match PMOD instances to PMOD Connectors
    
    # Instantiate OLED
    oled = OLED(OLED_Port)
    
    # Instantiate Digital to Analog Converter
    dac = DAC(DAC_Port)
    
    # Instantiate Analog to Digital Converter
    adc = ADC(ADC_Port)
  
    LED(switch_nmbr).off()
    while Switch(switch_nmbr).read():
        LED(switch_nmbr).on()
        for i in range (1, 11):
            dac.write(i/10)
            measured = adc.read()
            delay(delay_secs)
            print('Measurement {} equals: {}'.format(i, measured))
            oled.write(measured)
    LED(switch_nmbr).off()

if __name__ == '__main__':
    dac_loop()
