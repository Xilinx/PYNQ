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
__email__       = "xpp_support@xilinx.com"


from time import sleep
import struct
from . import _iop
from . import pmod_const
from pynq import MMIO

PROGRAM = "pmod_adc.bin"
PMOD_ADC_LOG_START = pmod_const.MAILBOX_OFFSET+16
PMOD_ADC_LOG_END = PMOD_ADC_LOG_START+(1000*4)

class PMOD_ADC(object):
    """This class controls an Analog to Digital Converter PMOD.
    
    The PMOD AD2 (PB 200-217) is an analog-to-digital converter powered by 
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

    def __init__(self, pmod_id):
        """Return a new instance of an ADC object.
    
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA). 
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
            
        """
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.mmio = self.iop.mmio
        self.log_running = 0
        
        self.iop.start()
    
    def reset(self):
        """Reset the PMOD ADC.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x1):
            sleep(0.001)
            
    def read_raw(self, delay=10, channel=0, samples=3):
        """Get the raw value from the ADC PMOD.
        
        All the 3 available channels are enabled. The default channel is 0, 
        meaning only the first channel is read. Users can choose any channel
        from 0 to 2. 
        
        In each channel, this method reads multiple samples and 
        returns the last sample. 
        
        The delay specifies the time between two samples, in milliseconds.
        
        Note
        ----
        The 4th channel is not available due to the jumper setting on ADC.
        
        Note
        ----
        This method reads the raw value from ADC.
        
        Parameters
        ----------
        delay : int
            The delay between samples on the same channel.
        channel : int
            The channel number, from 0 to 2.
        samples : int
            The number of samples read from each ADC channel.
        
        Returns
        -------
        int
            The raw value read from the PMOD ADC.
        
        """
        if (delay < 0):
            raise ValueError("Time between samples should be no less than 0.")
        if not channel in range(3):
            raise ValueError("Available channel is 0, 1, or 2.")
            
        #: Send the delay and the number of samples
        self.mmio.write(pmod_const.MAILBOX_OFFSET, delay)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+4, samples)
        
        #: Send the command
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        
        #: Wait for I/O processor to complete
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                              pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x3):
            sleep(0.001)

        #: Read the last sample from ADC
        return self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                        (3*samples+channel)*4)
        
    def read(self, delay=10, channel=0, samples=3):
        """Get the voltage from the ADC PMOD.
        
        All the 3 available channels are enabled. The default channel is 0, 
        meaning only the first channel is read. Users can choose any channel
        from 0 to 2. 
        
        In each channel, this method reads multiple samples and 
        returns the last sample. 
        
        The delay specifies the time between two samples, in milliseconds.
        
        Note
        ----
        The 4th channel is not available due to the jumper setting on ADC.
        
        Note
        ----
        This method reads the voltage values from ADC.
        
        Parameters
        ----------
        delay : int
            The delay between samples on the same channel.
        channel : int
            The channel number, from 0 to 2.
        samples : int
            The number of samples read from each ADC channel.
        
        Returns
        -------
        float
            The voltage value read from the PMOD ADC.
        
        """
        if (delay < 0):
            raise ValueError("Time between samples should be no less than 0.")
        if not channel in range(3):
            raise ValueError("Available channel is 0, 1, or 2.")
            
        #: Send the delay and the number of samples
        self.mmio.write(pmod_const.MAILBOX_OFFSET, delay)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+4, samples)
        
        #: Send the command
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
        
        #: Wait for I/O processor to complete
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                              pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x5):
            sleep(0.001)

        #: Read the last sample from ADC
        return self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                    (3*samples+channel)*4))
        
    def start_log_raw(self, channel=0, log_interval_ms=100):
        """Start the log of raw values with the interval specified.
        
        This parameter `log_interval_ms` can set the time interval between 
        two samples, so that users can read out multiple values in a single 
        log.  
        
        Parameters
        ----------
        channel : int
            The channel number, from 0 to 2.
        log_interval_ms : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if (log_interval_ms < 0):
            raise ValueError("Time between samples should be no less than 0.")
        if not channel in range(3):
            raise ValueError("Available channel is 0, 1, or 2.")
        
        self.log_running = 1
        
        #: Send log interval and the channel number
        self.mmio.write(pmod_const.MAILBOX_OFFSET, log_interval_ms)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+4, channel)
        
        #: Send the command
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
        
    def start_log(self, channel=0, log_interval_ms=100):
        """Start the log of voltage values with the interval specified.
        
        This parameter `log_interval_ms` can set the time interval between 
        two samples, so that users can read out multiple values in a single 
        log.  
        
        Parameters
        ----------
        channel : int
            The channel number, from 0 to 2.
        log_interval_ms : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if (log_interval_ms < 0):
            raise ValueError("Time between samples should be no less than 0.")
        if not channel in range(3):
            raise ValueError("Available channel is 0, 1, or 2.")
        
        self.log_running = 1
        
        #: Send log interval and the channel number
        self.mmio.write(pmod_const.MAILBOX_OFFSET, log_interval_ms)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+4, channel)
        
        #: Send the command
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)
        
    def stop_log_raw(self):
        """Stop the log of raw values.
        
        This is done by sending the reset command to IOP. There is no need to
        wait for the IOP.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        if(self.log_running == 1):
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")
            
    def stop_log(self):
        """Stop the log of voltage values.
        
        This is done by sending the reset command to IOP. There is no need to
        wait for the IOP.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        if(self.log_running == 1):
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")
                        
    def get_log_raw(self):
        """Get the log of raw values.
        
        First stop the log before getting the log.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        list
            List of valid raw samples from the ADC.
        
        """
        #: Stop logging
        self.stop_log_raw()

        #: Prep iterators and results list
        head_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0xC)
        readings = list()

        #: Sweep circular buffer for samples
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
        
        Parameters
        ----------
        None
        
        Returns
        -------
        list
            List of valid raw samples from the ADC.
        
        """
        #: Stop logging
        self.stop_log()

        #: Prep iterators and results list
        head_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(pmod_const.MAILBOX_OFFSET+0xC)
        readings = list()

        #: Sweep circular buffer for samples
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