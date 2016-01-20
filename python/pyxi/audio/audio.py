"""This module exposes API for an audio controller."""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from . import _audio
import pyb

class Audio(object):
    """Class for an audio controller.
    It just sets the static audio_ctrl variable.
    """
    audio_ctrl = None

    def __init__(self):
        if Audio.audio_ctrl is None:
           Audio.audio_ctrl = pyb.audio(_audio.audio_base_address, 
                                      _audio.audio_emio_pin, _audio.iicps_dict)

class LineIn(Audio):
    """Class for the audio LineIn channel."""
    def __init__(self):
        super().__init__()
        self.controller = Audio.audio_ctrl

    def __call__(self):
        """Gets the current content of both the L and R channel as a 
        list = [L,R].
        """
        return self.controller.input()

class Headphone(Audio):
    """Class for the audio headphone (HPH) channel."""
    def __init__(self):
        super().__init__()
        self.controller = Audio.audio_ctrl

    def __call__(self, channel_list):
        """Takes a list = [L,R] and outputs the value on both the left and 
        right channels.
        """
        self.controller.output(channel_list)
