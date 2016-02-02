"""This module exposes API for a VGA controller."""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.2"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from . import _video
from .frame import Frame
import pyb


class VGA(object):
    """Class for a VGA controller.

    Arguments
    ----------
    direction (str)                 : String whose value (either 'in' or 'out') 
                                      is used to indicate whether the VGA 
                                      instance is set as input or as output
    frame_buffer (pyb.video.frame)  : Assign this frame buffer if specified,
                                      otherwise create new

    Attributes
    ----------
    direction (str)                 : From argument *direction*
    """

    def __init__(self, direction, frame_buffer=None):
        """Return a new instance of a VGA object. currently only direction
        'out' is supported.
        """
        if direction.lower() == 'out':
            self.direction = 'out'
            if frame_buffer == None:
                self.display = pyb.video.display(_video.vdma_dict, 
                                                 _video.vtc_display_addr, 
                                                 _video.dyn_clk_addr, 1)
            else:
                self.display = pyb.video.display(_video.vdma_dict, 
                                                 _video.vtc_display_addr, 
                                                 _video.dyn_clk_addr, 1, 
                                                 frame_buffer)  
                                                     
            self.start = self.display.start
            """ Start the controller."""

            self.stop = self.display.stop
            """ Stop the controller."""

            self.state = self.display.state
            """ Get the state of the device as an integer value
            STOPPED = 0,
            RUNNING = 1.
            """

            self.mode = self.display.mode
            """ mode(new_mode_index)
            If 'new_mode_index' is not specified, get the current mode label. 
            If 'new_mode_index' is specified, set the mode to the new index and
            return the new mode label.
            new_mode_index must be within the allowed range
            0 : '640x480@60Hz'
            1 : '800x600@60Hz'
            2 : '1280x720@60Hz'
            3 : '1280x1024@60Hz'
            4 : '1920x1080@60Hz'           
            """

            #self.frame = self.display.frame
            #"""frame([index], [new_frame]) 
            #if 'index' is set, return the frame at the specified index, 
            #otherwise return the frame at the current index.
            #The frame is returned as a python list
            #frame[width][height][r,g,b].
#
            #if 'new_frame' is set (must be a python list 
            #frame[height][width][r,g,b]) the function does not return the
            #frame, but set it instead. So if in this case 'index' is specified,
            #'new_frame' is copied over the frame at 'index', otherwise
            #'new_frame' will overwrite the current frame.
            #"""


            self.frame = self._frame_out
            self.frame_raw = self._frame_raw_out


            self.frame_index = self.display.frame_index
            """ frame_index([new_frame_index])
            If 'new_frame_index' is not specified, get the current frame index. 
            If 'new_frame_index' is specified, set the current frame to the 
            new index.             
            """

            self.frame_index_next = self.display.frame_index_next
            """ frame_index_next()
            change the frame index to the next one and return its value.       
            """
            
            self.frame_width = self.display.frame_width
            """ Get the current frame width."""

            self.frame_height = self.display.frame_height
            """ Get the current frame height."""

            self.frame_buffer = self.display.frame_buffer
            """ Return the pyb.video.frame object that holds the frame buffer.
            Can be used to share the same frame buffer among different
            pyxi.video instances.
            """

        else:
            raise LookupError("Currently VGA supports direction='out' only.")

    def _frame_raw_out(self, *args):
        """frame_raw([index],[new_frame]) 
        Returns a bytearray (from a memoryview) of the frame buffer.
        if 'new_frame' is set, takes a bytearray ('new_frame' itself) 
        and  overwrites the current frame (or the frame specified by
        'index').

        User may simply use the non-raw version to ease indexing onto the 
        array, which however may introduce some overhead, negligible in 
        most cases. If speed is the primary concern, this version is the
        fastest, but, again, user must pay attetion when indexing
        onto the array.
        """
        if len(args) == 2:
            self.display.frame(args[0],args[1])
        elif len(args) == 1:
            if type(args[0]) is int:  #arg1 is 'index'
                return bytearray(self.display.frame(args[0]))
            else:
                self.display.frame(args[0])
        else:
            return bytearray(self.display.frame())

    def _frame_out(self, *args):
        """frame([index], [new_frame]) 
        Wraps the raw version using the Frame object.
        See frame.py for further info on how to use the Frame object.
        """   
        if len(args) == 2:
            self._frame_raw_out(args[0],args[1].frame)
        elif len(args) == 1:
            if type(args[0]) is int:  #arg1 is 'index'
                return Frame(self.frame_width(), self.frame_height(),
                             self._frame_raw_out(args[0]))
            else:
                self._frame_raw_out(args[0].frame)
        else:
            return Frame(self.frame_width(), self.frame_height(), 
                         self._frame_raw_out())