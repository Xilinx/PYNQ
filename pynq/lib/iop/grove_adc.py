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
__email__       = "pynq_support@xilinx.com"


import time
import struct
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO
from pynq.iop import PMOD_GROVE_G3
from pynq.iop import PMOD_GROVE_G4
from pynq.iop import ARDUINO_GROVE_I2C

PMOD_GROVE_ADC_PROGRAM = "pmod_grove_adc.bin"
ARDUINO_GROVE_ADC_PROGRAM = "arduino_grove_adc.bin"
GROVE_ADC_LOG_START = iop_const.MAILBOX_OFFSET+16
GROVE_ADC_LOG_END = GROVE_ADC_LOG_START+(1000*4)

class Grove_ADC(object):
    """This class controls the Grove IIC ADC. 
    
    Grove ADC is a 12-bit precision ADC module based on ADC121C021. Hardware
    version: v1.2.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_ADC.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between sampled reads of the Grove_ADC sensor.
        
    """
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove_ADC object. 
        
        Note
        ----
        The parameter `gr_pin` is a list organized as [scl_pin, sda_pin].
        
        Parameters
        ----------
        if_id : int
            The interface ID (1,2,3) corresponding to (PMODA,PMODB,ARDUINO).
        gr_pin: list
            A group of pins on stickit connector or arduino shield.
            
        """
        if if_id in [PMODA, PMODB]:
            if not gr_pin in [PMOD_GROVE_G3,
                              PMOD_GROVE_G4]:
                raise ValueError("ADC group number can only be G3 - G4.")
            GROVE_ADC_PROGRAM = PMOD_GROVE_ADC_PROGRAM
        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_I2C]:
                raise ValueError("ADC group number can only be I2C.")
            GROVE_ADC_PROGRAM = ARDUINO_GROVE_ADC_PROGRAM
        else:
            raise ValueError("No such IOP for grove device.")
            
        self.iop = request_iop(if_id, GROVE_ADC_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_interval_ms = 1000
        self.log_running  = 0
        self.iop.start()
        
        if if_id in [PMODA, PMODB]:
            # Write SCL and SDA pin config
            self.mmio.write(iop_const.MAILBOX_OFFSET, gr_pin[0])
            self.mmio.write(iop_const.MAILBOX_OFFSET+4, gr_pin[1])
            
            # Write configuration and wait for ACK
            self.mmio.write(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
            while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 1):
                pass
                
    def read_raw(self):
        """Read the ADC raw value from the Grove ADC peripheral.
        
        Returns
        -------
        int
            The raw value from the sensor.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET+
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 2)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 2):
            pass
        value = self.mmio.read(iop_const.MAILBOX_OFFSET)
        return value
        
    def read(self):
        """Read the ADC voltage from the Grove ADC peripheral.
        
        Returns
        -------
        float
            The float value after translation.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3):
            pass
        value = self.mmio.read(iop_const.MAILBOX_OFFSET)
        return self._reg2float(value)
        
    def set_log_interval_ms(self, log_interval_ms):
        """Set the length of the log for the Grove_ADC peripheral.
        
        This method can set the time interval between two samples, so that 
        users can read out multiple values in a single log. 
        
        Parameters
        ----------
        log_interval_ms : int
            The time between two samples in milliseconds, for logging only.
            
        Returns
        -------
        None
        
        """
        if log_interval_ms < 0:
            raise ValueError("Time between samples should be no less than 0.")
        
        self.log_interval_ms = log_interval_ms
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, self.log_interval_ms)

    def start_log_raw(self):
        """Start recording raw data in a log.
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO.
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(iop_const.MAILBOX_OFFSET + \
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 4)
                        
    def start_log(self):
        """Start recording multiple voltage values (float) in a log.
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO.
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(iop_const.MAILBOX_OFFSET + \
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 5)
                        
    def stop_log_raw(self):
        """Stop recording the raw values in the log.
        
        Simply write 0xC to the MMIO to stop the log.
            
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.mmio.write(iop_const.MAILBOX_OFFSET+ \
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 12)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")
            
    def stop_log(self):
        """Stop recording the voltage values in the log.
        
        This can be done by calling the stop_log_raw() method.
            
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 12)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")
        
    def get_log_raw(self):
        """Return list of logged raw samples.
            
        Returns
        -------
        list
            List of valid raw samples from the ADC sensor.
        
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
                readings.append(self.mmio.read(i))
        else:
            for i in range(head_ptr,GROVE_ADC_LOG_END,4):
                readings.append(self.mmio.read(i))
            for i in range(GROVE_ADC_LOG_START,tail_ptr,4):
                readings.append(self.mmio.read(i))
        return readings
        
    def get_log(self):
        """Return list of logged samples.
            
        Returns
        -------
        list
            List of valid voltage samples (floats) from the ADC sensor.
        
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
            for i in range(head_ptr,GROVE_ADC_LOG_END,4):
                readings.append(float("{0:.4f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
            for i in range(GROVE_ADC_LOG_START,tail_ptr,4):
                readings.append(float("{0:.4f}"\
                    .format(self._reg2float(self.mmio.read(i)))))
        return readings
        
    def reset(self):
        """Resets/initializes the ADC.
            
        Returns
        -------
        None
        
        """
        # Send command and wait for acknowledge
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 12)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 12):
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
