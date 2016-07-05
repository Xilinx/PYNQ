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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


from time import sleep
from math import log
from pynq.iop import pmod_const
from pynq.iop import Grove_ADC

class Grove_Light(Grove_ADC):
    """This class controls the grove light sensor.
    
    This class inherits from the Grove_ADC class. To use this module, grove 
    ADC has to be used as a bridge. The light sensor incorporates a Light 
    Dependent Resistor (LDR) GL5528. Hardware version: v1.1.
    
    Note
    ----
    The index of the PMOD pins:
    upper row, from left to right: {vdd,gnd,3,2,1,0}.
    lower row, from left to right: {vdd,gnd,7,6,5,4}.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove ADC.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between sampled reads of the Grove ADC sensor.
    
    """
    def __init__(self, pmod_id, gr_id): 
        """Return a new instance of an Grove ADC object. 
        
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        gr_id: int
            The group ID on StickIt, from 1 to 4.
            
        """
        if (gr_id not in [3,4]):
            raise ValueError("Valid StickIt group IDs are 3 and 4.")
        
        super().__init__(pmod_id, gr_id)
        
    def read(self):
        """Read the light sensor resistance in from the light sensor.
        
        This method overrides the definition in Grove_ADC.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The light reading in terms of the sensor resistance.
        
        """
        # Transform the ADC data into light value
        val = super().read_raw()
        return self._int2R(val)
        
    def start_log(self):
        """Start recording the light sensor resistance in a log.
        
        This method will call the start_log_raw() in the parent class.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        super().start_log_raw()
        
    def get_log(self):
        """Return list of logged light sensor resistances.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        list
            List of valid light sensor resistances.
        
        """
        # Stop and get the log
        r_log = super().get_log_raw()
        
        for i in range(len(r_log)):
            r_log[i] = self._int2R(r_log[i])
        return r_log
        
    def stop_log(self):
        """Stop recording light values in a log.
        
        This method will call the stop_log_raw() in the parent class.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        super().stop_log_raw()
        
    def _int2R(self, val):
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
        R_sensor = (4095.0 - val) * 10 / val
        return float("{0:.2f}".format(R_sensor))
        