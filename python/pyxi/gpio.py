
__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"

import os
import sys
import struct

class GPIO:
    """Class to handle (PS) GPIOs in Linux. This is differernt than the PMOD
    GPIO class.
    """
    
    def __init__(self, gpio_index, direction='in'):
        assert direction in ('in','out'), "direction should be in or out"
        self.index = gpio_index
        self.direction = direction
        self.path = '/sys/class/gpio/gpio%d/' % gpio_index
        
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('root permissions required.')
            exit()
        
        if not os.path.exists(self.path):
            try:
                with open('/sys/class/gpio/export', 'w') as f:
                    f.write(str(self.index))
            except IOError:
                print('cannot write into /sys/class/gpio/export')
                exit()
            
        try:
            with open(self.path + 'direction', 'w') as f:
                f.write(self.direction)
        except IOError:
            print('cannot write into',self.path)
            exit()

    """ Warning: Since the use of the following __del()__ function is not safe, 
    the GPIO drivers will be left in /sys/class/gpio/ directory, even 
    after exiting python prompt
    def __del__(self):
        if os.path.exists(self.path):
            try:
                with open('/sys/class/gpio/unexport', 'w') as f:
                    f.write(str(self.index))
            except IOError:
                print('cannot write into /sys/class/gpio/unexport')
    """

    def read(self):
        assert self.direction is 'in', "cannot read gpio output"
        try:
            with open(self.path + 'value', 'r') as f:
                return int(f.read())
        except IOError:
            print('cannot read from',self.path)

    def write(self, value): 
        assert self.direction is 'out', "cannot write gpio input"
        assert value in (0,1), "can only write 0 or 1"
        try:
            with open(self.path + 'value', 'w') as f:
                f.write(str(value))
            return
        except IOError:
            print('cannot write into',self.path)
            
