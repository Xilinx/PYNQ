"""This module exposes API for an HDMI controller."""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from . import _constants, _video
from .frame import Frame


class HDMI(object):
    """Class for an HDMI controller.

    Arguments
    ----------
    direction (str)                 : String whose value (either 'in' or 'out') 
                                      is used to indicate whether the HDMI 
                                      instance is set as input or as output
    frame_buffer (pyb.video.frame)  : Assign this frame buffer if specified,
                                      otherwise create new

    Attributes
    ----------
    direction (str)                 : From argument *direction*
    """

    def __init__(self, direction, frame_buffer=None):
        """Return a new instance of an HDMI object. currently only direction
        'in' is supported.
        """
        if direction.lower() == 'in':
            self.direction = 'in'
            if frame_buffer == None:
                self._capture = _video._capture(_constants.VDMA_DICT, 
                                                _constants.GPIO_DICT, 
                                                _constants.VTC_CAPTURE_ADDR)
            else:
                self._capture = _video._capture(_constants.VDMA_DICT, 
                                                _constants.GPIO_DICT, 
                                                _constants.VTC_CAPTURE_ADDR, 
                                                frame_buffer)

            self.start = self._capture.start
            """ Start the controller."""

            self.stop = self._capture.stop
            """ Stop the controller."""

            self.state = self._capture.state
            """ Get the state of the device as an integer value
            DISCONNECTED = 0,
            STREAMING = 1,
            PAUSED = 2.
            """

            self.frame_raw = self._capture.frame
            """frame_raw([index]) 
            Returns a bytearray (from a memoryview) of the frame buffer.

            User may simply use the non-raw version to ease indexing onto the 
            array, which however may introduce some overhead, negligible in 
            most cases. If speed is the primary concern, this version is the
            fastest, but, again, user must pay attetion when indexing
            onto the array.
            """

            self.frame = self._frame_in

            self.frame_index = self._capture.frame_index
            """ frame_index([new_frame_index])
            If 'new_frame_index' is not specified, get the current frame index. 
            If 'new_frame_index' is specified, set the current frame to the 
            new index.             
            """

            self.frame_index_next = self._capture.frame_index_next
            """ frame_index_next()
            change the frame index to the next one and return its value.       
            """

            self.frame_width = self._capture.frame_width
            """ Get the current frame width."""

            self.frame_height = self._capture.frame_height
            """ Get the current frame height."""

            self.frame_buffer = self._capture.framebuffer
            """ Return the pyb.video.frame object that holds the frame buffer.
            Can be used to share the same frame buffer among different
            pyxi.video instances.
            """

        else:
            raise LookupError("Currently HDMI supports direction='in' only.")    

    def _frame_in(self, index=None):
        """frame([index]) 
        Wraps the raw version using the Frame object.
        See frame.py for further info on how to use the Frame object.
        """
        buf = None
        if index is None:
            buf = self._capture.frame()
        else:
            buf = self._capture.frame(index)
        return Frame(self.frame_width(), self.frame_height(), buf)

    def __del__(self):
        self.stop() # may avoid odd behaviors of the DMA
        if hasattr(self, '_capture'):
            del self._capture
        elif hasattr(self, '_display'):
            del self._display
