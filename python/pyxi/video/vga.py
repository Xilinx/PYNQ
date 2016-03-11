
__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from .frame import Frame
from . import _constants
from . import _video


class VGA(object):
    """Class for a VGA controller.

    Parameters
    ----------
    direction : str
                String whose value (either 'in' or 'out') is used to indicate 
                whether the VGA instance is set as input or as output
    frame_buffer : pyxi.video._video._framebuffer 
                   Assign this frame buffer if specified, otherwise create new.
                   Can be used to share the same framebuffer among different
                   instances (e.g. a VGA and an HDMI objects).

    Attributes
    ----------
    direction : str
                From parameter :direction:

    Raises
    ------
    ValueError
        If direction is not set to 'out'. Currently VGA supports 
        direction='out' only.
    """

    def __init__(self, direction, frame_buffer=None):
        """Returns a new instance of a VGA object. 

        Currently only direction 'out' is supported.
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
            """Start the controller.

            Raises
            ------
            SystemError
                If unable to start the controller        
            """

            self.stop = self._display.stop
            """Stop the controller.

            Raises
            ------
            SystemError
                If unable to stop the controller        
            """

            self.state = self._display.state
            """Get the state of the device as an integer value

            Returns
            -------
            int
                STOPPED = 0,
                RUNNING = 1.
            """

            self.mode = self._display.mode
            """ mode(new_mode_index)

            Parameters
            ----------
            new_mode_index : {0, 1, 2, 3, 4}
                             must be within the allowed range:
                             0 : '640x480@60Hz'
                             1 : '800x600@60Hz'
                             2 : '1280x720@60Hz'
                             3 : '1280x1024@60Hz'
                             4 : '1920x1080@60Hz'           
                             If `new_mode_index` is not specified, return the 
                             current mode label. If instead is specified, set 
                             the mode to the new index and return the new 
                             mode label.

            Returns
            ---------
            str
                a label representing the currently active mode

            Raises
            ------
            ValueError
                If `new_mode_index` is out of range
            """

            self.frame_raw = self._display.frame
            """frame_raw([index],[new_frame]) 

            Returns a bytearray of the frame buffer.

            User may simply use the non-raw version to ease indexing onto the 
            array, which however may introduce some overhead, negligible in 
            most cases. If speed is the primary concern, this version is the
            fastest, but, again, user must pay attetion when indexing
            onto the array.

            Parameters
            ----------
            index : int, optional
                    If specified, consider the frame at that index.
                    Otherwise, consider the frame at the current active index
            new_frame: bytearray, optional
                       If `new_frame` is set, takes a bytearray 
                       (`new_frame` itself) and  overwrites the current frame 
                       (or the frame specified by `index`).                        

            Returns
            -------
            bytearray
                the frame in its raw bytearray form. If `new_frame` is set,
                **nothing** is returned.
            """

            self.frame = self._frame_out
            """frame([index], [new_frame]) 

            Wraps the raw version using the Frame object.
            See frame.py for further info on how to use the Frame object.

            Parameters
            ----------
            index : int, optional
                    Index of the frame to consider within the 
                    framebuffer
            new_frame : pyxi.video.Frame, optional
                        new frame to copy into the frame buffer      

            Returns
            -------
            pyxi.video.Frame 
                If `new_frame` is set, **nothing** is returned.           
            """

            self.frame_index = self._display.frame_index
            """ frame_index([new_frame_index])

            Parameters
            ----------
            index : int, optional
                    If is not specified, get the current frame index. 
                    If specified, set the current frame to the new index.  

            Returns
            -------
            int
                the active frame index 

            Raises
            ------
            ValueError
                If `index` is out of range
            SystemError
                If unable to change the frame index     
            """

            self.frame_index_next = self._display.frame_index_next
            """Change the frame index to the next one and return its value.   

            Returns
            -------
            int
                the active frame index  

            Raises
            ------
            SystemError
                If unable to change the frame index              
            """

            self.frame_width = self._display.frame_width
            """ Get the current frame width.

            Returns
            -------
            int
            """

            self.frame_height = self._display.frame_height
            """ Get the current frame height.

            Returns
            -------
            int
            """

            self.frame_buffer = self._display.framebuffer
            """ The `pyxi.video._video._framebuffer` object that holds 
            the frame buffer. 

            Can be used to share the same frame buffer among different
            pyxi.video instances.

            Examples
            --------
            >>> hdmi = HDMI('in')
            >>> vga = VGA('out', hdmi.frame_buffer)          
            """

        else:
            raise ValueError("Currently VGA supports direction='out' only.")

    def _frame_out(self, *args):
        if len(args) == 2:
            self._display.frame(args[0], args[1].frame)
        elif len(args) == 1:
            if type(args[0]) is int:  # arg1 is 'index'
                return Frame(self.frame_width(), self.frame_height(),
                             self._display.frame(args[0]))
            else:
                self._display.frame(args[0].frame)
        else:
            return Frame(self.frame_width(), self.frame_height(),
                         self._display.frame())

    def __del__(self):
        self.stop()  # may avoid odd behaviors of the DMA
        if hasattr(self, '_capture'):
            del self._capture
        elif hasattr(self, '_display'):
            del self._display
