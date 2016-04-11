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
    """This class controls a light sensor PMOD.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by GROVE_ADC
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_interval_ms : int
        Time in milliseconds between sampled reads of the GROVE_ADC sensor
        
    """
    def __init__(self, pmod_id):
        """Return a new instance of an GROVE_ADC object. 
        
        Parameters
        ----------
        pmod_id : int
            Requested PMOD index from list of all PMOD IO Processors in the
            programmable logic.  Indexing starts at 1.
            
        """
        self.iop = _iop.request_iop(pmod_id, GROVE_ADC_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_interval_ms = 1000
        self.log_int_running = 0
        self.log_float_running = 0
        self.high_level = 0
        self.low_level = 0
        self.hysteresis_level = 0
        
        self.iop.start()
        
    def read(self):
        """Read the ADC value from the GROVE_ADC peripheral.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        int
            The current sensor value.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return value

    def read_float(self):
        """Read the ADC value from the GROVE_ADC peripheral.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The current sensor value.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 5)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 5):
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
        """Start recording multiple int values in a log.
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO. S
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        self.log_int_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 7)
                        
    def start_log_float(self):
        """Start recording multiple float values in a log.
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        self.log_float_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 9)

    def stop_log(self):
        """Stop recording multiple int values in a log.
        
        Simply write to the MMIO to stop the log.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        if(self.log_int_running == 1):
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
            self.log_int_running = 0
        else:
            if(self.log_float_running == 1):
               raise ValueError("Error: Float log is running. Try stop_log_float()")
            else:
               raise ValueError("Error: No log running")
    
    def stop_log_float(self):
        """Stop recording multiple float values in a log.
        
        Simply write to the MMIO to stop the log.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        if(self.log_float_running == 1):
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
            self.log_float_running = 0
        else:
            if(self.log_int_running == 1):
               raise ValueError("Error: Int log is running. Try stop_log() or get_log()")
            else:
               raise ValueError("Error: No log running")   
               
    def get_log(self):
        """Return list of logged samples.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        List of valid int samples from the GROVE_ADC sensor 
        
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

    def get_log_float(self):
        """Return list of logged samples.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        List of valid float voltage samples from the GROVE_ADC sensor [0V - ~3.3V]
        
        """
        #: Stop logging
        self.stop_log_float()

        # prep iterators and results list
        head_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0xC)
        readings = list()

        # sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,4):
                readings.append(float("{0:.3f}".format(self._reg2float(self.mmio.read(i)))))
        else:
            for i in range(head_ptr,GROVE_ADC_LOG_END,4):
                readings.append(float("{0:.3f}".format(self._reg2float(self.mmio.read(i)))))
            for i in range(GROVE_ADC_LOG_START,tail_ptr,4):            
                readings.append(float("{0:.3f}".format(self._reg2float(self.mmio.read(i)))))
        return readings
 
    def set_low_level(self,low_level):
        """Set the low threshold for the Grove ADC. 
        
        Values read below this value will trigger a status alarm
        
        Parameters
        ----------
        low_level : To Do: determine type/range
            The value of the low level
            
        Returns
        -------
        None
        
        """
        if (low_level < 0):
            raise ValueError("High level should not be less than 0.")
        
        self.low_level = low_level
        self.mmio.write(pmod_const.MAILBOX_OFFSET, self.low_level) 
        # send command and wait for acknowledge
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 11)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 11):
            pass
            
    def set_high_level(self,high_level):
        """Set the low threshold for the Grove ADC. 
        
        Values above this value will trigger a status alarm
        
        Parameters
        ----------
        high_level : To Do: determine type/range
            The value of the low level
            
        Returns
        -------
        None
        
        """
        if (high_level < 0):
            raise ValueError("High level should not be less than 0.")
        
        self.high_level = high_level
        self.mmio.write(pmod_const.MAILBOX_OFFSET, self.high_level)     
        # send command and wait for acknowledge
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 13)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 13):
            pass  
        
    def set_hysteresis_level(self,hysteresis_level):
        """Sets the hysteresis for the Low/High Alarms
        
        Parameters
        ----------
        hysteresis_level : To Do: determine type/range
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if (hysteresis_level < 0):
            raise ValueError("High level should not be less than 0.")
        
        self.hysteresis_level = hysteresis_level
        self.mmio.write(pmod_const.MAILBOX_OFFSET, self.hysteresis_level) 
        # send command and wait for acknowledge
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 15)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 15):
            pass
    
    def read_lowest(self):
        """Read the lowest value the ADC has read
        
        Parameters
        ----------
        None
        
        Returns
        -------
        int
            The lowest logged value.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 17)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 17):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return value

    def read_highest(self):
        """Read the higest value the ADC has read
        
        Parameters
        ----------
        None
        
        Returns
        -------
        int
            The highest logged value.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 19)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 19):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return value

    def read_status(self):
        """Read the ADC status, including low/high alarms
        
        Parameters
        ----------
        None
        
        Returns
        -------
        int
            The current ADC status.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 21)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 21):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return value
        
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
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 23)      
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 23):
            pass
            
    def _reg2float(self, reg):
        """Converts int to float representation
        
        Parameters
        ----------
        reg: int
            
        Returns
        -------
        float
        
        """
        s = struct.pack('>l', reg)
        return struct.unpack('>f', s)[0]
