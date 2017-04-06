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

__author__      = "Marco Rabozzi, Luca Cerina, Giuseppe Natale"
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

PMOD_GROVE_HAPTIC_MOTOR_PROGRAM = "pmod_grove_haptic_motor.bin"
ARDUINO_GROVE_HAPTIC_MOTOR_PROGRAM = "arduino_grove_haptic_motor.bin"

class Grove_Haptic_Motor(object):
    """This class controls the Grove Haptic Motor based on the DRV2605L.
    Hardware version v0.9. 
    
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_Haptic_Motor.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove_Haptic_Motor object. 
                
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
                raise ValueError("Motor group number can only be G3 - G4.")
            GROVE_HAPTIC_MOTOR_PROGRAM = PMOD_GROVE_HAPTIC_MOTOR_PROGRAM

        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_I2C]:
                raise ValueError("Motor group number can only be I2C.")
            GROVE_HAPTIC_MOTOR_PROGRAM = ARDUINO_GROVE_HAPTIC_MOTOR_PROGRAM

        else:
            raise ValueError("No such IOP for grove device.")

        self.iop = request_iop(if_id, GROVE_HAPTIC_MOTOR_PROGRAM)
        self.mmio = self.iop.mmio
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

    def play(self, effect):
        """Play a vibration effect on the Grove Haptic Motor peripheral.

        Valid effect identifiers are in the range [1, 127].
        
        Parameters
        ----------
        effect : int
            An integer that specifies the effect.
        
        Returns
        -------
        None 
        
        """
        if (effect < 1) or (effect > 127):
            raise ValueError("Valid effect identifiers are within 1 and 127.")
        self.mmio.write(iop_const.MAILBOX_OFFSET, effect)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, 0)
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 2)  
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 2):
            pass

    def play_sequence(self, sequence):
        """Play a sequence of effects possibly separated by pauses.

        At most 8 effects or pauses can be specified at a time.
        Pauses are defined using negative integer values in the 
        range [-1, -127] that correspond to a pause length in the 
        range [10, 1270] ms

        Valid effect identifiers are in the range [1, 127]

        As an example, in the following sequence example: [4,-20,5] 
        effect 4 is played and after a pause of 200 ms effect 5 is played
        
        Parameters
        ----------
        sequence : list
            At most 8 values specifying effects and pauses.
        
        Returns
        -------
        None 
        
        """
        length = len(sequence) 
        if length < 1:
            raise ValueError("The sequence must contain at least one value.")
        if length > 8:
            raise ValueError("The sequence cannot contain more than 8 values.")
        for i in range(length):
            if sequence[i] < 0:
                if sequence[i] < -127:
                    raise ValueError("Pause value must be smaller than -127")
                sequence[i] = -sequence[i] + 128
            else:
                if (sequence[i] < 1) or (sequence[i] > 127):
                    raise ValueError("Valid effect identifiers are within " + \
                                     "1 and 127.")

        # pad the sequence with zeros
        sequence += [0]*(8 - length)

        for i in range(0,8):
            self.mmio.write(iop_const.MAILBOX_OFFSET+i*4, sequence[i])
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 2)  
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 2):
            pass



    def stop(self):
        """Stop an effect or a sequence on the motor peripheral.
            
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)  
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3):
            pass
                        
    def is_playing(self):
        """Check if a vibration effect is running on the motor.
            
        Returns
        -------
        bool
            True if a vibration effect is playing, false otherwise
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 4)  
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 4):
            pass
        if self.mmio.read(iop_const.MAILBOX_OFFSET) == 1:
            return True
        return False