def main():
    '''
    DAC writes a value -> ADC measures the value -> OLED displays the value
    '''
    # 1. Load PMOD classes from Python-Xilinx library (pyxi.pmods)
    from pyxi.pmods import OLED, ADC, DAC
    
    # Match PMOD instances to PMOD Connectors
    
    # 2. instantiate OLED
    oled = OLED(3)
    
    # 3. instantiate Digital to Analog Converter
    dac = DAC(2)
    
    # 4. instantiate Analog to Digital Converter
    adc = ADC(1)
    
    # 5. Set DAC output voltage
    dac.write(0.75)
    
    # 6. Measure output of DAC with ADC
    value = adc.read()
    
    # 7. Display measured value on OLED
    oled.write(value)

if __name__ == '__main__':
    main()