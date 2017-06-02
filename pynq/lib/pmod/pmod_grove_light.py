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


from . import Grove_ADC


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _int2r(val):
    """Convert the integer value to the light sensor resistance.

    This method should only be used internally.

    Note
    ----
    A smaller returned value indicates a higher brightness. Resistance 
    value ranges from 5.0 (brightest) to 35.0 (darkest).

    Parameters
    ----------
    val : int
        The raw data read from grove ADC.

    Returns
    -------
    float
        The light sensor resistance indicating the light intensity.

    """
    if 0 < val <= 4095:
        r_sensor = (4095.0 - val) * 10 / val
    else:
        raise RuntimeError("Value out of range or device not connected.")
    return float("{0:.2f}".format(r_sensor))


class Grove_Light(Grove_ADC):
    """This class controls the grove light sensor.
    
    This class inherits from the grove ADC class. To use this module, grove 
    ADC has to be used as a bridge. The light sensor incorporates a Light 
    Dependent Resistor (LDR) GL5528. Hardware version: v1.1.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between sampled reads.
    
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove ADC object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.
            
        """
        super().__init__(mb_info, gr_pin)

    def read(self):
        """Read the light sensor resistance in from the light sensor.
        
        This method overrides the definition in grove ADC.
        
        Returns
        -------
        float
            The light reading in terms of the sensor resistance.
        
        """
        val = super().read_raw()
        return _int2r(val)
        
    def start_log(self):
        """Start recording the light sensor resistance in a log.
        
        This method will call the start_log_raw() in the parent class.
            
        Returns
        -------
        None
        
        """
        super().start_log_raw()
        
    def get_log(self):
        """Return list of logged light sensor resistances.
            
        Returns
        -------
        list
            List of valid light sensor resistances.
        
        """
        r_log = super().get_log_raw()
        return [_int2r(i) for i in r_log]

    def stop_log(self):
        """Stop recording light values in a log.
        
        This method will call the stop_log_raw() in the parent class.
            
        Returns
        -------
        None
        
        """
        super().stop_log_raw()
