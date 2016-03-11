
__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"

from . import _constants
from . import _audio


class Audio(object):
    """Class for an audio controller.

    This class just sets the static `_audio_ctrl` variable if not yet set.
    The `_audio_ctrl` is used by `LineIn` and `Headpone` classes that inherits
    from `Audio`
    """
    _audio_ctrl = None

    def __init__(self):
        if Audio._audio_ctrl is None:
            Audio._audio_ctrl = _audio._audio(_constants.AUDIO_BASE_ADDRESS,
                                              _constants.AUDIO_GPIO_PIN,
                                              _constants.IICPS_INDEX)


class LineIn(Audio):
    """Class for the audio LineIn channel."""

    def __init__(self):
        super().__init__()
        self.controller = Audio._audio_ctrl

    def __call__(self):
        """Gets the current content of both the L and R channels as a 
        list = [L,R].

        Returns
        ----------
        list
            A two-elements list = [L,R] that holds the content of the 
            L and R channels
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

        Parameters
        ----------
        channel_list : list
                       A two-elements list = [L,R] containing the value 
                       to output to the L and R channels
        """
        self.controller.output(channel_list)
