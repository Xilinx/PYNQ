"""This module exposes API for an audio controller."""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"

from . import _constants, _audio

class Audio(object):
    """Class for an audio controller.
    It just sets the static _audio_ctrl variable.
    """
    _audio_ctrl = None

    def __init__(self):
        if Audio._audio_ctrl is None:
           Audio._audio_ctrl = _audio._audio(_constants.audio_base_address, 
                                             _constants.audio_gpio_pin, 
                                             _constants.iicps_index)

class LineIn(Audio):
    """Class for the audio LineIn channel."""
    def __init__(self):
        super().__init__()
        self.controller = Audio._audio_ctrl

    def __call__(self):
        """Gets the current content of both the L and R channel as a 
        list = [L,R].
        """
        return self.controller.input()

class Headphone(Audio):
    """Class for the audio headphone (HPH) channel."""
    def __init__(self):
        super().__init__()
        self.controller = Audio._audio_ctrl

    def __call__(self, channel_list):
        """Takes a list = [L,R] and outputs the value on both the left and 
        right channels.
        """
        self.controller.output(channel_list)
