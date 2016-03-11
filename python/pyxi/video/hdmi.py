
__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from .frame import Frame
from . import _constants
from . import _video


class HDMI(object):
    """Class for an HDMI controller.

    Parameters
    ----------
    direction : str
                String whose value (either 'in' or 'out') is used to indicate 
                whether the HDMI instance is set as input or as output
    frame_buffer : pyxi.video._video._framebuffer 
                   Assign this frame buffer if specified, otherwise create new.
                   Can be used to share the same framebuffer among different
                   instances (e.g. a VGA and an HDMI objects).

    Attributes
    ----------
    direction : str
                From parameter `direction`

    Raises
    ------
    ValueError
        If direction is not set to 'in'. Currently HDMI supports 
        direction='in' only.
    """

    def __init__(self, direction, frame_buffer=None):
        """Returns a new instance of an HDMI object. 

        Currently only direction 'in' is supported.
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
            """Start the controller.

            Raises
            ------
            SystemError
                If unable to start the controller        
            """

            self.stop = self._capture.stop
            """Stop the controller.

            Raises
            ------
            SystemError
                If unable to stop the controller        
            """

            self.state = self._capture.state
            """Get the state of the device as an integer value.

            Returns
            -------
            int
                DISCONNECTED = 0,
                STREAMING = 1,
                PAUSED = 2.
            """

            self.frame_raw = self._capture.frame
            """frame_raw([index]) 

            get the frame as a bytearray

            User may simply use the non-raw version to ease indexing onto the 
            array, which however may introduce some overhead, negligible in 
            most cases. If speed is the primary concern, this version is the
            fastest, but, again, user must pay attetion when indexing
            onto the array.

            Parameters
            ----------
            index : int, optional
                    If specified, get the frame at that index.
                    Otherwise, get the frame at the current active index

            Returns
            -------
            bytearray
                the frame in its raw bytearray form
            """

            self.frame = self._frame_in
            """frame([index]) 

            Wraps the raw version using the Frame object.
            See `frame.py` for further info on how to use the Frame object.

            Parameters
            ----------
            index : int, optional
                    Index of the frame to consider within the frame buffer

            Returns
            -------
            pyxi.video.Frame
            """

            self.frame_index = self._capture.frame_index
            """frame_index([new_frame_index])

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

            self.frame_index_next = self._capture.frame_index_next
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

            self.frame_width = self._capture.frame_width
            """ Get the current frame width.

            Returns
            -------
            int
            """

            self.frame_height = self._capture.frame_height
            """ Get the current frame height.

            Returns
            -------
            int
            """

            self.frame_buffer = self._capture.framebuffer
            """The `pyxi.video._video._framebuffer` object that holds 
            the frame buffer.

            Can be used to share the same frame buffer among different
            pyxi.video instances.

            Examples
            --------
            >>> hdmi = HDMI('in')
            >>> vga = VGA('out', hdmi.frame_buffer)          
            """

        else:
            raise ValueError("Currently HDMI supports direction='in' only.")

    def _frame_in(self, index=None):
        buf = None
        if index is None:
            buf = self._capture.frame()
        else:
            buf = self._capture.frame(index)
        return Frame(self.frame_width(), self.frame_height(), buf)

    def __del__(self):
        self.stop()  # may avoid odd behaviors of the DMA
        if hasattr(self, '_capture'):
            del self._capture
        elif hasattr(self, '_display'):
            del self._display
