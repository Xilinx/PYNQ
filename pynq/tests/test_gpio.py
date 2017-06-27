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


import os
import math
import pytest
from pynq.gpio import GPIO, GPIO_MIN_USER_PIN


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


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
