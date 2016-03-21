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
from . import video_const
from . import _video

class HDMI(object):
    """Class for an HDMI controller.

    The frame buffer in an HDMI object can be shared among different objects.
    For example, a VGA object and an HDMI object can use the same frame buffer.
    
    Note
    ----
    Currently HDMI only supports direction 'in'.
    
    Examples
    --------
    >>> hdmi = HDMI('in')
    
    Attributes
    ----------
    direction : str
        Can only be 'in' for HDMI to be input.
    frame_buffer : _framebuffer
        A frame buffer storing at most 3 frames.
        
    Raises
    ------
    ValueError
        If direction is not set to 'in'.
        
    """

    def __init__(self, direction, frame_buffer=None):
        """Returns a new instance of an HDMI object. 
        
        Assign the given frame buffer if specified, otherwise create a new 
        frame buffer.
        
        Note
        ----
        Currently HDMI only supports direction 'in'.
        
        Parameters
        ----------
        direction : str
            Can only be 'in' for HDMI to be input.
        frame_buffer : optional[_framebuffer] 
            A frame buffer storing at most 3 frames.
        
        """
        if not direction.lower() == 'in':
            raise ValueError("Currently HDMI only supports input.")
        else:
            self.direction = 'in'
            if frame_buffer == None:
                self._capture = _video._capture(video_const.VDMA_DICT,
                                                video_const.GPIO_DICT,
                                                video_const.VTC_CAPTURE_ADDR)
            else:
                self._capture = _video._capture(video_const.VDMA_DICT,
                                                video_const.GPIO_DICT,
                                                video_const.VTC_CAPTURE_ADDR,
                                                frame_buffer)
                                                
            self.frame_buffer = self._capture.framebuffer
            
            self.start = self._capture.start
            """Start the video controller.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            None
            
            """
            
            self.stop = self._capture.stop
            """Stop the video controller.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            None
            
            """
            
            self.state = self._capture.state
            """Get the state of the device as an integer value.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The state 0 (DISCONNECTED), or 1 (STREAMING), or 2 (PAUSED).
                
            """
            
            self.frame_raw = self._capture.frame
            """Get the frame as a bytearray.
            
            User may use frame([index]) to access the frame, which may 
            introduce some overhead in rare cases. The method frame_raw([i]) 
            is faster, but the parameter `i` has to be calculated manually.
            
            Parameters
            ----------
            i : optional[int]
                A location in the bytearray.
                
            Returns
            -------
            bytearray
                The frame in its raw bytearray form.
                
            """
            
            self.frame = self._frame_in
            """Wraps the raw version using the Frame object.
            
            Use frame([index]) to read the frame more easily.
            
            Parameters
            ----------
            index : optional[int]
                Index of the frames, from 0 to 2.
                
            Returns
            -------
            Frame
                A Frame object with accessible pixels.
                
            """

            self.frame_index = self._capture.frame_index
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

            self.frame_index_next = self._capture.frame_index_next
            """Change the frame index to the next one.

            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The index of the active frame.
            
            """

            self.frame_width = self._capture.frame_width
            """Get the current frame width.

            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The width of the frame.
                
            """

            self.frame_height = self._capture.frame_height
            """Get the current frame height.
            
            Parameters
            ----------
            None
            
            Returns
            -------
            int
                The height of the frame.
                
            """

    def _frame_in(self, index=None):
        """Returns the specified frame or the active frame.
        
        Parameters
        ----------
        index : optional[int]
            The index of a frame in the frame buffer, from 0 to 2.
            
        Returns
        -------
        Frame
            An object of a frame in the frame buffer.
            
        """
        buf = None
        if index is None:
            buf = self._capture.frame()
        else:
            buf = self._capture.frame(index)
        return Frame(self.frame_width(), self.frame_height(), buf)

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
