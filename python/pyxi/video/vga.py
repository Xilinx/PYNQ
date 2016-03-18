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

__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from .frame import Frame
from . import _constants
from . import _video

class VGA(object):
    """Class for a VGA controller.

    The frame buffer in a VGA object can be shared among different objects.
    For example, a VGA object and an HDMI object can use the same frame buffer.
    
    Note
    ----
    Currently VGA only supports direction 'out'.
    
    Examples
    --------
    >>> vga = VGA('out', frame_buffer)
    
    Attributes
    ----------
    direction : str
        Can only be 'out' for VGA to be output.
    frame_buffer : _framebuffer
        A frame buffer storing at most 3 frames.
        
    Raises
    ------
    ValueError
        If direction is not set to 'out'.
        
    """

    def __init__(self, direction, frame_buffer=None):
        """Returns a new instance of a VGA object. 
        
        Assign the given frame buffer if specified, otherwise create a new 
        frame buffer.
        
        Note
        ----
        Currently VGA only supports direction 'out'.
        
        Parameters
        ----------
        direction : str
            Can only be 'out' for VGA to be output.
        frame_buffer : optional[_framebuffer] 
            A frame buffer storing at most 3 frames.
        
        """
        if not direction.lower() == 'out':
            raise ValueError("Currently VGA only supports output.")
        else:
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
                                                
            self.frame_buffer = self._display.framebuffer
            
            self.start = self._display.start
            """Start the video controller.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            None
            
            """

            self.stop = self._display.stop
            """Stop the video controller.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            None
            
            """

            self.state = self._display.state
            """Get the state of the device as an integer value.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The state 0 (STOPPED), or 1 (RUNNING).
                
            """

            self.mode = self._display.mode
            """Change the resolution of the display. 
            
            Users can use mode(new_mode) to change the resolution.
            Specifically, with `new_mode` to be:
            0 : '640x480@60Hz'
            1 : '800x600@60Hz'
            2 : '1280x720@60Hz'
            3 : '1280x1024@60Hz'
            4 : '1920x1080@60Hz'           
            
            If `new_mode` is not specified, return the current mode.

            Parameters
            ----------
            new_mode : int
                A mode index from 0 to 4.
                
            Returns
            -------
            str
                The resolution of the VGA display.
                
            Raises
            ------
            ValueError
                If `new_mode` is out of range.
                
            """

            self.frame_raw = self._display.frame
            """Returns a bytearray of the frame.
            
            User may use frame([index]) to access the frame, which may 
            introduce some overhead in rare cases. The method 
            frame_raw([i],[new_frame]) is faster, but the parameter `i` has 
            to be calculated manually.

            Note
            ----
            If `new_frame` is set, this method will take the bytearray 
            (`new_frame`) and overwrites the current frame (or the frame 
            specified by `i`). Also, if `new_frame` is set, nothing will 
            be returned.
            
            Parameters
            ----------
            i : optional[int]
                A location in the bytearray.
            new_frame: optional[bytearray]
                A bytearray that can be used to overwrite the frame.
                
            Returns
            -------
            bytearray
                The frame in its raw bytearray form.
                
            """

            self.frame = self._frame_out
            """Wraps the raw version using the Frame object.
            
            Use frame([index], [new_frame]) to write the frame more easily.
            
            Note
            ----
            if `new_frame` is set, nothing will be returned.
            
            Parameters
            ----------
            index : optional[int]
                Index of the frames, from 0 to 2.
            new_frame : optional[Frame]
                A new frame to copy into the frame buffer.
                
            Returns
            -------
            Frame
                A Frame object with accessible pixels.
                
            """

            self.frame_index = self._display.frame_index
            """Get the frame index.
            
            Use frame_index([new_frame_index]) to access the frame index.
            If `new_frame_index` is not specified, get the current frame index. 
            If `new_frame_index` is specified, set the current frame to the 
            new index. 

            Parameters
            ----------
            new_frame_index : optional[int]
                Index of the frames, from 0 to 2.
                
            Returns
            -------
            int
                The index of the active frame.
                
            """

            self.frame_index_next = self._display.frame_index_next
            """Change the frame index to the next one.

            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The index of the active frame.
            
            """

            self.frame_width = self._display.frame_width
            """Get the current frame width.

            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The width of the frame.
                
            """

            self.frame_height = self._display.frame_height
            """Get the current frame height.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The height of the frame.
                
            """

    def _frame_out(self, *args):
        """Returns the specified frame or the active frame.
        
        Note
        ----
        With no parameter specified, this method returns a new Frame object.
        With 1 parameter specified, this method uses it as the index or frame
        to create the Frame object. 
        With 2 parameters specified, this method treats the first argument as 
        index, while treating the second argument as a frame.
        
        Parameters
        ----------
        *args
            Variable length argument list.
            
        Returns
        -------
        Frame
            An object of a frame in the frame buffer.
            
        """
        if len(args) == 2:
            self._display.frame(args[0], args[1].frame)
        elif len(args) == 1:
            if type(args[0]) is int:
                return Frame(self.frame_width(), self.frame_height(),
                                self._display.frame(args[0]))
            else:
                self._display.frame(args[0].frame)
        else:
            return Frame(self.frame_width(), self.frame_height(),
                         self._display.frame())

    def __del__(self):
        """Delete the HDMI object.
        
        Stop the video controller first to avoid odd behaviors of the DMA.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.stop()
        if hasattr(self, '_capture'):
            del self._capture
        elif hasattr(self, '_display'):
            del self._display
