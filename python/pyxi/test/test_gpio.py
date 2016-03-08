__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"
        
 
import pytest
import os, math
from pyxi import GPIO, Overlay


@pytest.mark.run(order=3)
def test_gpio():
    """ Test whether the GPIO class is working properly.
    Note:
        The gpio_min is the GPIO base pin number + minimum user pin
        The gpio_max is the smallest power of 2 greater than the GPIO base. 
        This may not be true for other boards.
    """
    ol = Overlay()
    gpio_min = ol.get_gpio_base() + 54
    gpio_max = 2**(math.ceil(math.log(gpio_min, 2)))
    
    for index in range(gpio_min, gpio_max):
        g = GPIO(index, 'in')
        assert type(g.read()) is int, 'gpio read returned wrong type'
        with pytest.raises(Exception) as error_infor:
            """ GPIO type is 'in'. Hence g.write() is illegal. 
            Test will pass if exception is raised.
            """
            g.write()
        
        g.delete()
        with pytest.raises(Exception) as error_infor:
            """ After the deletion of the GPIO pin, raise exception if it is 
            read again.
            """
            g.read()
        
        g = GPIO(index, 'out')
        with pytest.raises(Exception) as error_infor:
            """ GPIO type is 'out'. Hence g.read() is illegal. 
            Test will pass if exception is raised.
            """
            g.read()
        with pytest.raises(Exception) as error_infor:
            """ write() only accepts integer 0 or 1 (not 'str'). 
            Test will pass if exception is raised.
            """
            g.write('1')
        
        g.delete()
        with pytest.raises(Exception) as error_infor:
            """ After the deletion of the GPIO pin, raise exception if it is 
            written again.
            """
            g.write(1)