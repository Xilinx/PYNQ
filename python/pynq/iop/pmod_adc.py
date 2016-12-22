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

__author__      = "Graham Schelle, Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com" 


import struct
from time import sleep
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB

PMOD_ADC_PROGRAM = "pmod_adc.bin"
PMOD_ADC_LOG_START = iop_const.MAILBOX_OFFSET+16
PMOD_ADC_LOG_END = PMOD_ADC_LOG_START+(1000*4)

class Pmod_ADC(object):
    """This class controls an Analog to Digital Converter Pmod.
    
    The Pmod AD2 (PB 200-217) is an analog-to-digital converter powered by 
    AD7991. Users may configure up to 4 conversion channels at 12 bits of 
    resolution.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by the ADC
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_running : int
        The state of the log (0: stopped, 1: started).
        
    """

    def __init__(self, if_id):
        """Return a new instance of an ADC object.
        
        Parameters
        ----------
        if_id : int
            The interface ID (1, 2) corresponding to (PMODA, PMODB).
            
        """
        if not if_id in [PMODA, PMODB]:
            raise ValueError("No such IOP for Pmod device.")
            
        self.iop = request_iop(if_id, PMOD_ADC_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_running = 0
        
        self.iop.start()
    
    def reset(self):
        """Reset the Pmod ADC.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET + 
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x1):
            sleep(0.001)
            
    def read_raw(self, ch1=1, ch2=0, ch3=0):
        """Get the raw value from the Pmod ADC.
        
        When ch1, ch2, and ch3 values are 1 then the corresponding channel
        is included. 
        
        For each channel selected, this method reads and returns one sample. 
        
                
        Note
        ----
        The 4th channel is not available due to the jumper (JP1) setting on 
        ADC.
        
        Note
        ----
        This method reads the raw value from ADC.
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        
        Returns
        -------
        list
            The raw values read from the 3 channels of the Pmod ADC.
        
        """
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        cmd= (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | 3    
       
        # Send the command
        self.mmio.write(iop_const.MAILBOX_OFFSET + 
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd)
        
        # Wait for I/O processor to complete
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET + 
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

        # Read the samples from ADC
        readings=[]
        if ch1:
            readings.append(self.mmio.read(iop_const.MAILBOX_OFFSET))
        if ch2:
            readings.append(self.mmio.read(iop_const.MAILBOX_OFFSET+4))
        if ch3:
            readings.append(self.mmio.read(iop_const.MAILBOX_OFFSET+8))
        return readings
        
    def read(self, ch1=1, ch2=0, ch3=0):
        """Get the voltage from the Pmod ADC.
        
        When ch1, ch2, and ch3 values are 1 then the corresponding channel
        is included. 
        
        For each channel selected, this method reads and returns one sample. 
               
        Note
        ----
        The 4th channel is not available due to the jumper setting on ADC.
        
        Note
        ----
        This method reads the voltage values from ADC.
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        
        Returns
        -------
        list
            The voltage values read from the 3 channels of the Pmod ADC.
        
        """
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        cmd= (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | 5    
       
        # Send the command
        self.mmio.write(iop_const.MAILBOX_OFFSET + 
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd)
        
        # Wait for I/O processor to complete
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET + 
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

        # Read the last sample from ADC
        readings=[]
        if ch1:
            readings.append(self._reg2float(self.mmio.read(
                                        iop_const.MAILBOX_OFFSET)))
        if ch2:
            readings.append(self._reg2float(self.mmio.read(
                                        iop_const.MAILBOX_OFFSET+4)))
        if ch3:
            readings.append(self._reg2float(self.mmio.read(
                                        iop_const.MAILBOX_OFFSET+8)))
        return readings
        
    def start_log_raw(self, ch1=1, ch2=0, ch3=0, log_interval_us=100):
        """Start the log of raw values with the interval specified.
        
        This parameter `log_interval_us` can set the time interval between 
        two samples, so that users can read out multiple values in a single 
        log.  
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        log_interval_us : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if log_interval_us < 0:
            raise ValueError("Time between samples should be no less than 0.")
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        
        cmd= (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | 7    
        
        self.log_running = 1
        
        # Send log interval
        self.mmio.write(iop_const.MAILBOX_OFFSET, log_interval_us)
        
        # Send the command
        self.mmio.write(iop_const.MAILBOX_OFFSET+\
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd)
        
    def start_log(self, ch1=1, ch2=0, ch3=0, log_interval_us=100):
        """Start the log of voltage values with the interval specified.
        
        This parameter `log_interval_us` can set the time interval between 
        two samples, so that users can read out multiple values in a single 
        log.  
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        log_interval_us : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if log_interval_us < 0:
            raise ValueError("Time between samples should be no less than 0.")
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        
        cmd= (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | 9    
        
        self.log_running = 1
        
        # Send log interval and the channel number
        self.mmio.write(iop_const.MAILBOX_OFFSET, log_interval_us)
        
        # Send the command
        self.mmio.write(iop_const.MAILBOX_OFFSET+\
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd)
        
    def stop_log_raw(self):
        """Stop the log of raw values.
        
        This is done by sending the reset command to IOP. There is no need to
        wait for the IOP.
        
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.mmio.write(iop_const.MAILBOX_OFFSET+
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")
            
    def stop_log(self):
        """Stop the log of voltage values.
        
        This is done by sending the reset command to IOP. There is no need to
        wait for the IOP.
        
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.mmio.write(iop_const.MAILBOX_OFFSET+\
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")
                        
    def get_log_raw(self):
        """Get the log of raw values.
        
        First stop the log before getting the log.
        
        Returns
        -------
        list
            List of raw samples from the ADC.
        
        """
        # Stop logging
        self.stop_log_raw()

        # Prep iterators and results list
        head_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0xC)
        readings = list()

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,4):
                readings.append(self.mmio.read(i))
        else:
            for i in range(head_ptr,PMOD_ADC_LOG_END,4):
                readings.append(self.mmio.read(i))
            for i in range(PMOD_ADC_LOG_START,tail_ptr,4):
                readings.append(self.mmio.read(i))
        return readings
        
    def get_log(self):
        """Get the log of voltage values.
        
        First stop the log before getting the log.
        
        Returns
        -------
        list
            List of voltage samples from the ADC.
        
        """
        # Stop logging
        self.stop_log()

        # Prep iterators and results list
        head_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0xC)
        readings = list()

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,4):
                readings.append(float("{0:.4f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
        else:
            for i in range(head_ptr,PMOD_ADC_LOG_END,4):
                readings.append(float("{0:.4f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
            for i in range(PMOD_ADC_LOG_START,tail_ptr,4):
                readings.append(float("{0:.4f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
        return readings
        
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
        return round(struct.unpack('>f', s)[0], 4)