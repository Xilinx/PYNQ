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

__author__      = "Parimal Patel"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import time
import struct
from . import _iop
from . import pmod_const
from pynq import MMIO

GROVE_BUZZER_PROGRAM = "grove_buzzer.bin"

class Grove_Buzzer(object):
    """This class controls the Grove Buzzer.
    
    The grove buzzer module has a piezo buzzer as the main component. 
    The piezo can be connected to digital outputs, and will emit a tone 
    when the output is HIGH. Alternatively, it can be connected to an analog 
    pulse-width modulation output to generate various tones and effects.
    Hardware version: v1.2.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by GROVE_Buzzer
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_interval_ms : int
        Time in milliseconds between sampled reads of the GROVE_ADC sensor
        
    """
    def __init__(self, pmod_id, gr_id): 
        """Return a new instance of an GROVE_Buzzer object. 
        
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
        if (gr_id not in range(1,5)):
            raise ValueError("Valid StickIt group ID is 1, 2, 3 or 4.")

        self.iop = _iop.request_iop(pmod_id, GROVE_BUZZER_PROGRAM)
        self.mmio = self.iop.mmio
        
        self.iop.start()
        
    def play_melody(self):
        """Play a melody.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
                
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        
    def play_tone(self, tone_period, num_cycles):
        """Play a single tone with tone_period for num_cycles
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        if (tone_period not in range(1,32768)):
            raise ValueError("Valid tone period is between 1 and 32767.")
        if (num_cycles not in range(1,32768)): 
            raise ValueError("Valid number of cycles is between 1 and 32767.")
        
        cmd_word = (tone_period << 16) | (num_cycles << 1) | 0x0
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
            pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd_word)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
            pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            