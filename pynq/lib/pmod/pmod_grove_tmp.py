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


from math import log
from . import Grove_ADC


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class Grove_TMP(Grove_ADC):
    """This class controls the grove temperature sensor.
    
    This class inherits from the Grove_ADC class. To use this module, grove 
    ADC has to be used as a bridge. The temperature sensor uses a thermistor 
    to detect the ambient temperature. Hardware version: v1.2.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between sampled reads.
    bValue : int
        The thermistor constant.
    
    """
    def __init__(self, mb_info, gr_pin, version='v1.2'):
        """Return a new instance of a Grove_TMP object. 
        
        Note
        ----
        The parameter `gr_pin` is a list organized as [scl_pin, sda_pin].
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.
        version : str
            The hardware version number (can be found on device).

        """
        if version == 'v1.2':
            # v1.2 uses NCP18WF104F03RC
            self.bValue = 4250
        elif version == 'v1.1':
            # v1.1 uses thermistor NCP18WF104F03RC
            self.bValue = 4250
        else:
            # v1.0 uses thermistor TTC3A103*39H
            self.bValue = 3975

        super().__init__(mb_info, gr_pin)

    def read(self):
        """Read temperature values in Celsius from temperature sensor.
        
        This method overrides the definition in Grove_ADC.
        
        Returns
        -------
        float
            The temperature reading in Celsius.
        
        """
        # Transform the ADC data into degree Celsius
        val = super().read_raw()
        return self._int2temp(val)
        
    def start_log(self):
        """Start recording temperature in a log.
        
        This method will call the start_log_raw() in the parent class.
        
        """
        super().start_log_raw()
        
    def get_log(self):
        """Return list of logged temperature samples.
            
        Returns
        -------
        list
            List of valid temperature readings from the temperature sensor.
        
        """
        # Stop and get the log
        tmp_log = super().get_log_raw()
        return [self._int2temp(i) for i in tmp_log]

    def stop_log(self):
        """Stop recording temperature in a log.
        
        This method will call the stop_log_raw() in the parent class.
            
        Returns
        -------
        None
        
        """
        super().stop_log_raw()

    def _int2temp(self, val):
        """Convert the integer value to temperature in Celsius.
        
        This method should only be used internally.
        
        Parameters
        ----------
        val : int
            The raw data read from grove ADC.
        
        Returns
        -------
        float
            The temperature reading in Celsius.
        
        """
        try:
            r = 4095.0/val - 1.0
            temp = 1.0/(log(r)/self.bValue + 1/298.15)-273.15
        except ZeroDivisionError:
            raise RuntimeError("Value out of range or device not connected.")
        return float("{0:.2f}".format(temp))
