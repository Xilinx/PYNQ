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

__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


from pynq import PL
from . import _audio

AUDIO_GPIO_PIN = 194
IICPS_INDEX = 1

class Audio(object):
    """Class for the audio controller.

    This class just sets the static `_audio_ctrl` variable if not yet set.
    The `_audio_ctrl` in `LineIn` and `Headpone` classes inherits from `Audio`.
    
    Attributes
    ----------
    _audio_ctrl : object
        An audio control object from C-API.
        
    """
    _audio_ctrl = None

    def __init__(self):
        """Return a new instance of an Audio object.
        
        All the attributes of the Audio is shared by its child classes 
        LineIn and Headphone.
        
        Parameters
        ----------
        None
            
        """
        if Audio._audio_ctrl is None:
            Audio._audio_ctrl = _audio._audio(
                        int(PL.ip_dict["SEG_zybo_audio_ctrl_0_reg0"][0],16),
                        AUDIO_GPIO_PIN,
                        IICPS_INDEX)

class LineIn(Audio):
    """Class for the audio LineIn channel.
    
    This is a child class of Audio.
    
    Attributes
    ----------
    controller : object
        Uses the audio controller in its parent class (C-API).
    
    """

    def __init__(self):
        """Return a new instance of a LineIn oject.
        
        Parameters
        ----------
        None
            
        """
        super().__init__()
        self.controller = Audio._audio_ctrl

    def __call__(self):
        """Gets the current content of both the L and R channels
        
        The content is returned as a list of [L,R].

        Parameters
        ----------
        None
        
        Returns
        -------
        list
            A two-elements list [L,R] holding the contents of both channels.
            
        """
        return self.controller.input()


class Headphone(Audio):
    """Class for the audio headphone (HPH) channel.
    
    This is a child class of Audio.
    
    Attributes
    ----------
    controller : object
        Uses the audio controller in its parent class (C-API).
    
    """

    def __init__(self):
        """Return a new instance of a Headphone oject.
        
        Parameters
        ----------
        None
            
        """
        super().__init__()
        self.controller = Audio._audio_ctrl

    def __call__(self, channel_list):
        """Takes a list and outputs the value on both channels.

        Parameters
        ----------
        channel_list : list
            A two-elements list [L,R] holding the contents of both channels.
        """
        self.controller.output(channel_list)
