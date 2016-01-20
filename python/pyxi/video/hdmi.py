"""This module exposes API for an HDMI controller."""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.2"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from . import _video
from .frame import Frame
import pyb


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
                self.capture = pyb.video.capture(_video.vdma_dict, 
                                                 _video.gpio_dict, 
                                                 _video.vtc_capture_addr, 
                                                 _video.gpio_intr, 
                                                 _video.vtc_intr)
            else:
                self.capture = pyb.video.capture(_video.vdma_dict, 
                                                 _video.gpio_dict, 
                                                 _video.vtc_capture_addr, 
                                                 _video.gpio_intr, 
                                                 _video.vtc_intr, 
                                                 frame_buffer)

            self.start = self.capture.start
            """ Start the controller."""

            self.stop = self.capture.stop
            """ Stop the controller."""

            self.state = self.capture.state
            """ Get the state of the device as an integer value
            DISCONNECTED = 0,
            STREAMING = 1,
            PAUSED = 2.
            """

            #self.frame = self.capture.frame
            #"""frame([index]) 
            #if 'index' is set, return the frame at the specified index, 
            #otherwise return the frame at the current index.
            #The frame is returned as a python list
            #frame[height][width][r,g,b].
            #"""

            self.frame = self._frame_in
            self.frame_raw = self._frame_raw_in

            self.frame_index = self.capture.frame_index
            """ frame_index([new_frame_index])
            If 'new_frame_index' is not specified, get the current frame index. 
            If 'new_frame_index' is specified, set the current frame to the 
            new index.             
            """

            self.frame_index_next = self.capture.frame_index_next
            """ frame_index_next()
            change the frame index to the next one and return its value.       
            """

            self.frame_width = self.capture.frame_width
            """ Get the current frame width."""

            self.frame_height = self.capture.frame_height
            """ Get the current frame height."""

            self.frame_buffer = self.capture.frame_buffer
            """ Return the pyb.video.frame object that holds the frame buffer.
            Can be used to share the same frame buffer among different
            pyxi.video instances.
            """

        else:
            raise LookupError("Currently HDMI supports direction='in' only.")

    def _frame_raw_in(self, index=None):
        """frame_raw([index]) 
        Returns a bytearray (from a memoryview) of the frame buffer.

        User may simply use the non-raw version to ease indexing onto the 
        array, which however may introduce some overhead, negligible in 
        most cases. If speed is the primary concern, this version is the
        fastest, but, again, user must pay attetion when indexing
        onto the array.
        """
        if index is not None:
          return bytearray(self.capture.frame(index))
        else:
          return bytearray(self.capture.frame())        

    def _frame_in(self, index=None):
        """frame([index]) 
        Wraps the raw version using the Frame object.
        See frame.py for further info on how to use the Frame object.
        """
        buf = _frame_raw_in(self, index)
        return Frame(self.frame_width(), self.frame_height(), buf)
