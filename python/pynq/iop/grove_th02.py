#   Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
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

__author__      = "Lorenzo Di Tucci, Marco Rabozzi, Giuseppe Natale"
__copyright__   = "Copyright 2016, NECST Laboratory, Politecnico di Milano"

import time
import struct
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import Pmod_IO
from pynq.iop import Arduino_IO
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO
from pynq.iop import PMOD_GROVE_G3
from pynq.iop import PMOD_GROVE_G4
from pynq.iop import ARDUINO_GROVE_I2C


PMOD_GROVE_TH02_PROGRAM = "pmod_grove_th02.bin"
ARDUINO_GROVE_TH02_PROGRAM = "arduino_grove_th02.bin"
GROVE_TH02_LOG_START = iop_const.MAILBOX_OFFSET+16
GROVE_TH02_LOG_END = GROVE_TH02_LOG_START+(500*8)

class Grove_TH02(object):
    """This class controls the Grove I2C Temperature and Humidity sensor. 
    
    Temperature & humidity sensor (high-accuracy & mini).
    Hardware version: v1.0.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_TH02.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_running : int
        The state of the log (0: stopped, 1: started).
        
    """
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove_TH02 object. 
                
        Parameters
        ----------
        if_id : int
            IOP ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
        gr_pin: list
            A group of pins on stickit connector or arduino shield.
            
        """
        if if_id in [PMODA, PMODB]:
            if not gr_pin in [PMOD_GROVE_G3,
                              PMOD_GROVE_G4]:
                raise ValueError("TH02 group number can only be G3 - G4.")
            GROVE_TH02_PROGRAM = PMOD_GROVE_TH02_PROGRAM

        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_I2C]:
                raise ValueError("TH02 group number can only be I2C.")
            GROVE_TH02_PROGRAM = ARDUINO_GROVE_TH02_PROGRAM

        else:
            raise ValueError("No such IOP for grove device.")

        self.iop = request_iop(if_id, GROVE_TH02_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_interval_ms = 1000
        self.log_running  = 0
        self.iop.start()

        if if_id in [PMODA, PMODB]:        
            #: Write SCL and SDA Pin Config
            self.mmio.write(iop_const.MAILBOX_OFFSET, gr_pin[0])
            self.mmio.write(iop_const.MAILBOX_OFFSET+4, gr_pin[1])
            
        # Write configuration and wait for ACK
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 1):
            pass  
            
    def read(self):
        """Read the temperature and humidity values from the TH02 peripheral.
        
        Returns
        -------
        tuple
            tuple containing (temperature, humidity)
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 2)      
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 2):
            pass
        tmp = self.mmio.read(iop_const.MAILBOX_OFFSET)
        tmp = tmp/32 - 50

        humidity = self.mmio.read(iop_const.MAILBOX_OFFSET + 0x4)
        humidity = humidity/16 - 24
        return tmp, humidity

    def start_log(self, log_interval_ms = 100):
        """Start recording multiple heart rate values in a log.
        
        This method will first call set the log interval before writting to
        the MMIO.
        
        Parameters
        ----------
        log_interval_ms : int
            The time between two samples in milliseconds.
            
        Returns
        -------
        None
        
        """
        if log_interval_ms < 0:
            raise ValueError("Time between samples cannot be less than zero.")

        self.log_running = 1
        self.log_interval_ms = log_interval_ms
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, self.log_interval_ms)
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)
                        
    def stop_log(self):
        """Stop recording the values in the log.
        
        Simply write 0xC to the MMIO to stop the log.
            
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 13)
            self.log_running = 0
        else:
            raise RuntimeError("No grove TH02 log running.")


    def get_log(self):
        """Return list of logged samples.
            
        Returns
        -------
        list
            List of tuples containing (temperature, humidity)
        
        """
        # stop logging
        self.stop_log()

        #: Prep iterators and results list
        head_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0xC)
        readings = list()

        # sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,8):
                temp = self.mmio.read(i)/32 - 50
                humid = self.mmio.read(i + 0x4)/16 - 24
                readings.append((temp,humid))
        else:
            for i in range(head_ptr,GROVE_TH02_LOG_END,8):
                temp = self.mmio.read(i)/32 - 50
                humid = self.mmio.read(i + 0x4)/16 - 24
                readings.append((temp,humid))
            for i in range(GROVE_TH02_LOG_END,tail_ptr,8):
                temp = self.mmio.read(i)/32 - 50
                humid = self.mmio.read(i + 0x4)/16 - 24
                readings.append((temp,humid))
        return readings