"""This module exposes API for a VGA controller."""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from . import _constants, _video


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
                self._display = _video._display(_constants.VDMA_DICT, 
                                                _constants.VTC_DISPLAY_ADDR, 
                                                _constants.DYN_CLK_ADDR, 1)
            else:
                self._display = _video._display(_constants.VDMA_DICT, 
                                                _constants.VTC_DISPLAY_ADDR, 
                                                _constants.DYN_CLK_ADDR, 1, 
                                                frame_buffer)  
                                                     
            self.start = self._display.start
            """ Start the controller."""

            self.stop = self._display.stop
            """ Stop the controller."""

            self.state = self._display.state
            """ Get the state of the device as an integer value
            STOPPED = 0,
            RUNNING = 1.
            """

            self.mode = self._display.mode
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

            self.frame_raw = self._display.frame
            """frame_raw([index],[new_frame]) 
            Returns a bytearray of the frame buffer.
            if 'new_frame' is set, takes a bytearray ('new_frame' itself) 
            and  overwrites the current frame (or the frame specified by
            'index').

            User may simply use the non-raw version to ease indexing onto the 
            array, which however may introduce some overhead, negligible in 
            most cases. If speed is the primary concern, this version is the
            fastest, but, again, user must pay attetion when indexing
            onto the array.
            """

            self.frame = self._frame_out

            self.frame_index = self._display.frame_index
            """ frame_index([new_frame_index])
            If 'new_frame_index' is not specified, get the current frame index. 
            If 'new_frame_index' is specified, set the current frame to the 
            new index.             
            """

            self.frame_index_next = self._display.frame_index_next
            """ frame_index_next()
            change the frame index to the next one and return its value.       
            """
            
            self.frame_width = self._display.frame_width
            """ Get the current frame width."""

            self.frame_height = self._display.frame_height
            """ Get the current frame height."""

            self.frame_buffer = self._display.framebuffer
            """ Return the pyb.video.frame object that holds the frame buffer.
            Can be used to share the same frame buffer among different
            pyxi.video instances.
            """
            
            self.stop() # avoid odd behaviors of the DMA
        else:
            raise LookupError("Currently VGA supports direction='out' only.")

    def _frame_out(self, *args):
        """frame([index], [new_frame]) 
        Wraps the raw version using the Frame object.
        See frame.py for further info on how to use the Frame object.
        """   
        if len(args) == 2:
            self._display.frame(args[0],args[1].frame)
        elif len(args) == 1:
            if type(args[0]) is int:  #arg1 is 'index'
                return Frame(self.frame_width(), self.frame_height(),
                             self._display.frame(args[0]))
            else:
                self._display.frame(args[0].frame)
        else:
            return Frame(self.frame_width(), self.frame_height(), 
                         self._display.frame())

    def __del__(self):
        self.stop() # avoid odd behaviors of the DMA
