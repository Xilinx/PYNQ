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

__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from itertools import chain
from PIL import Image
from . import _video
from . import video_const

class Frame(object):
    """This class exposes the bytearray of the video frame buffer.

    Note
    ----
    The maximum frame width is 1920, while the maximum frame height is 1080.
    
    Attributes
    ----------
    frame : bytearray
        The bytearray of the video frame buffer.
    width : int
        The width of a frame.
    height : int
        The height of a frame.
        
    """

    def __init__(self, width, height, frame=None):
        """Returns a new Frame object.
        
        Note
        ----
        The maximum frame width is 1920; the maximum frame height is 1080.
        
        Parameters
        ----------
        width : int
            The width of a frame.
        height : int
            The height of a frame.
            
        """
        if frame is not None:
            self._framebuffer = None
            self.frame = frame
        else:
            # Create a framebuffer with just 1 frame
            self._framebuffer = _video._frame(1)
            # Create an empty frame
            self.frame = self._framebuffer(0)
        self.width = width
        self.height = height

    def __getitem__(self, pixel):
        """Get one pixel in a frame.

        The pixel is accessed in the following way: 
            `frame[x, y]` to get the tuple (r,g,b) 
        or 
            `frame[x, y][rgb]` to access a specific color.
            
        Examples
        --------
        Get the three component of pixel (48,32) as a tuple, assuming the 
        object is called `frame`:
        
        >>> frame[48,32]
        (128,64,12)

        Access the green component of pixel (48,32):
        >>> frame[48,32][1]
        64
        
        Note
        ----
        The original frame stores pixels as (g,b,r). Hence, to return a tuple 
        (r,g,b), we need to return (self.frame[offset+2], self.frame[offset],
        self.frame[offset+1]).
            
        Parameters
        ----------
        pixel : list
            A pixel (r,g,b) of a frame.
            
        Returns
        -------
        list
            A list of the current values (r,g,b) of the pixel.
            
        """
        x, y = pixel
        if 0 <= x < self.width and 0 <= y < self.height:
            offset = 3 * (y * video_const.MAX_FRAME_WIDTH + x)
            
            return self.frame[offset+2],self.frame[offset],\
                    self.frame[offset+1]
        else:
            raise ValueError("Pixel is out of the frame range.")

    def __setitem__(self, pixel, value):
        """Set one pixel in a frame.

        The pixel is accessed in the following way: 
            `frame[x, y] = (r,g,b)` to set the entire tuple
        or 
            `frame[x, y][rgb] = value` to set a specific color.

        Examples
        --------
        Set pixel (0,0), assuming the object is called `frame`:
        
        >>> frame[0,0] = (255,255,255)
        
        Set the blue component of pixel (0,0) to be 128
        
        >>> frame[0,0][2] = 128
        
        Note
        ----
        The original frame stores pixels as (g,b,r).
        
        Parameters
        ----------
        pixel : list
            A pixel (r,g,b) of a frame.
        value : list
            A list of the values (r,g,b) to be set for the pixel.
            
        Returns
        -------
        None
        
        """
        x, y = pixel
        if 0 <= x < self.width and 0 <= y < self.height:
            offset = 3 * (y * video_const.MAX_FRAME_WIDTH + x)
            self.frame[offset + 2] = value[0]
            self.frame[offset] = value[1]
            self.frame[offset + 1] = value[2]
        else:
            raise ValueError("Pixel is out of the frame range.")

    def __del__(self):
        """Delete the frame buffer.
        
        Delete the frame buffer and free the memory only if the frame buffer 
        is not empty.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        if self._framebuffer is not None:
            del self._framebuffer

    def save_as_jpeg(self, path):
        """Save a video frame to a JPEG image.

        Note
        ----
        The JPEG filename must be included in the path.
        
        Parameters
        ----------
        path : str
            The path where the JPEG will be saved.
            
        Returns
        -------
        None
        
        """
        rgb = bytearray()
        for i in range(self.height):
            row = self.frame[i * video_const.MAX_FRAME_WIDTH * 3 :\
                            (i * video_const.MAX_FRAME_WIDTH + self.width) * 3]
            rgb.extend(bytearray(
                        chain.from_iterable((row[j+2], row[j], row[j+1])\
                            for j in range(0, len(row)-1, 3))))

        image = Image.frombytes('RGB', (self.width,self.height), bytes(rgb))
        image.save(path, 'JPEG')

    @staticmethod
    def save_raw_as_jpeg(path, frame_raw, width, height):
        """Save a video frame (in bytearray) to a JPEG image.
        
        Note
        ----
        This is a static method of the class.

        Parameters
        ----------
        path : str
            The path where the JPEG will be saved.
        frame_raw : bytearray
            The video frame to be saved.
        width : int
            The width of the frame.
        height : int
            The height of the frame.
            
        Returns
        -------
        None
        
        """
        rgb = bytearray()
        for i in range(height):
            row = frame_raw[i * video_const.MAX_FRAME_WIDTH * 3 :\
                            (i * video_const.MAX_FRAME_WIDTH + width) * 3]
            rgb.extend(bytearray(
                        chain.from_iterable((row[j+2], row[j], row[j+1])\
                           for j in range(0, len(row)-1, 3))))

        image = Image.frombytes('RGB', (width, height), bytes(rgb))
        image.save(path, 'JPEG')
