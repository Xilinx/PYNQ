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

__author__      = "Cathal McCabe"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import time
import struct
from . import _iop
from . import pmod_const
from pynq import MMIO

GROVE_ADC_PROGRAM = "grove_adc.bin"
GROVE_ADC_LOG_START = pmod_const.MAILBOX_OFFSET+16
GROVE_ADC_LOG_END = GROVE_ADC_LOG_START+(1000*4)

class Grove_ADC(object):
    """This class controls the Grove IIC ADC. 

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by GROVE_ADC
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_interval_ms : int
        Time in milliseconds between sampled reads of the GROVE_ADC sensor
        
    """
    def __init__(self, pmod_id, gr_id): 
        """Return a new instance of an GROVE_ADC object. 
        
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
        # IOP Switch Configuration
        if (gr_id not in range(3,5)):
            raise ValueError("Valid StickIt ID for ADC (IIC) is 4. ")

        self.iop = _iop.request_iop(pmod_id, GROVE_ADC_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_interval_ms = 1000
        self.log_running  = 0
        self.iop.start()
 
        # Configure IOP Switch
        # SDA is configuration 0x9 
        # SCL is configuration 0x8
        # Format of data to be sent is [7:4] configuration, [3:0] is pin
        SDA = 0x90
        SCL = 0x80
        
        # Write SCL Pin Config
        pin_config = SCL + pmod_const.STICKIT_PINS_GR[gr_id][0];   
        # Write Pin Config
        self.mmio.write(pmod_const.MAILBOX_OFFSET, pin_config)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)      
        #Wait for ACK
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 1):
            pass
        # Write SDA Pin Config    
        pin_config = SDA + pmod_const.STICKIT_PINS_GR[gr_id][1];   
        # Write Pin Config
        self.mmio.write(pmod_const.MAILBOX_OFFSET, pin_config)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)      
        #Wait for ACK
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 1):
            pass
        
        
    def read(self):
        """Read the ADC value from the GROVE_ADC peripheral.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        int
            The raw value from the sensor.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 2)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 2):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return value
        
    def read_voltage(self):
        """Read the ADC voltage from the GROVE_ADC peripheral.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The float value after translation.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return self._reg2float(value)
        
    def set_log_interval_ms(self,log_interval_ms):
        """Set the length of the log for the GROVE_ADC peripheral.
        
        This method can set the length of the log, so that users can read out
        multiple values in a single log. 
        
        Parameters
        ----------
        log_interval_ms : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if (log_interval_ms < 0):
            raise ValueError("Log length should not be less than 0.")
        
        self.log_interval_ms = log_interval_ms
        self.mmio.write(pmod_const.MAILBOX_OFFSET+4, self.log_interval_ms)

    def start_log(self):
        """Start recording raw data in a log.
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 4)
                        
    def start_log_voltage(self):
        """Start recording multiple voltage values (float) in a log.
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 5)   
                        
    def stop_log(self):
        """Stop recording multiple float values in a log.
        
        Simply write 0 to the MMIO to stop the log.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        if(self.log_running == 1):
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
            self.log_running = 0
        else:
            raise ValueError("Error: No log running")   
               
    def get_log(self):
        """Return list of logged samples.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        list
            List of valid voltage samples (floats) from the GROVE_ADC sensor.
        
        """
        #: Stop logging
        self.stop_log()

        # prep iterators and results list
        head_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0xC)
        readings = list()

        # sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,4):
                readings.append(self.mmio.read(i))
        else:
            for i in range(head_ptr,GROVE_ADC_LOG_END,4):
                readings.append(self.mmio.read(i))
            for i in range(GROVE_ADC_LOG_START,tail_ptr,4):            
                readings.append(self.mmio.read(i))
        return readings
    def get_log_voltage(self):
        """Return list of logged samples.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        list
            List of valid voltage samples (floats) from the GROVE_ADC sensor.
        
        """
        #: Stop logging
        self.stop_log()

        # prep iterators and results list
        head_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0xC)
        readings = list()

        # sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,4):
                readings.append(float("{0:.3f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
        else:
            for i in range(head_ptr,GROVE_ADC_LOG_END,4):
                readings.append(float("{0:.3f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
            for i in range(GROVE_ADC_LOG_START,tail_ptr,4):
                readings.append(float("{0:.3f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
        return readings
        
    def reset_adc(self):
        """Resets/initializes the ADC
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """

        # send command and wait for acknowledge
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 12)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 12):
            pass
            
    def _reg2float(self, reg):
        """Converts 32-bit register value to floats in Python.
        
        Parameters
        ----------
        reg: int
            A 32-bit register value read from the mailbox.
            
        Returns
        -------
        float
            A float number translated from the register value.
        
        """
        s = struct.pack('>l', reg)
        return struct.unpack('>f', s)[0]
