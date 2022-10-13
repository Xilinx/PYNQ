#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import os
import math
import pytest
from pynq.gpio import GPIO, GPIO_MIN_USER_PIN




@pytest.mark.run(order=3)
def test_gpio():
    """ Test whether the GPIO class is working properly.
    
    Note
    ----
    The gpio_min is the GPIO base pin number + minimum user pin
    The gpio_max is the smallest power of 2 greater than the GPIO base.
    
    """
    # Find the GPIO base pin
    index = 0
    for root, dirs, files in os.walk('/sys/class/gpio'):
        for name in dirs:
            if 'gpiochip' in name:
                index = int(''.join(x for x in name if x.isdigit()))
                break
    base = GPIO.get_gpio_base()
    assert base == index, 'GPIO base not parsed correctly.'

    gpio_min = base + GPIO_MIN_USER_PIN
    gpio_max = 2**int(math.ceil(math.log(gpio_min, 2)))

    for index in range(gpio_min, gpio_max):
        g = GPIO(index, 'in')
        with pytest.raises(Exception):
            # GPIO type is 'in'. Hence g.write() is illegal. 
            g.write()
        del g
        
        g = GPIO(index, 'out')
        with pytest.raises(Exception):
            # GPIO type is 'out'. Hence g.read() is illegal. 
            g.read()
        with pytest.raises(Exception):
            # write() only accepts integer 0 or 1 (not 'str'). 
            g.write('1')
        
        del g


