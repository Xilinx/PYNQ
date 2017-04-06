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
__email__ = "pynq_support@xilinx.com"

from pynq import PL
from time import sleep
import numpy as np
from PIL import Image
from . import _video

MAX_FRAME_WIDTH = 1920
MAX_FRAME_HEIGHT = 1080
VMODE_1920x1080 = 4
VMODE_1280x1024 = 3
VMODE_1280x720  = 2
VMODE_800x600   = 1
VMODE_640x480   = 0

class HDMI(object):
    """Class for an HDMI controller.
    
    The frame buffer in an HDMI object can be shared among different objects.
    e.g., HDMI in and HDMI out objects can use the same frame buffer.
    
    Note
    ----
    HDMI supports direction 'in' and 'out'.
    
    Examples
    --------
    >>> hdmi = HDMI('in')
    
    >>> hdmi = HDMI('out')
    
    Attributes
    ----------
    direction : str
        Can be 'in' for HDMI IN or 'out' for HDMI OUT.
    frame_list : _framebuffer
        A frame buffer storing at most 3 frames.
        
    """
    def __init__(self, direction, video_mode=VMODE_640x480,
                 init_timeout=10, frame_list=None,
                 vdma_name='SEG_axi_vdma_0_Reg',
                 display_name='SEG_v_tc_0_Reg',
                 capture_name='SEG_v_tc_1_Reg',
                 clk_name='SEG_axi_dynclk_0_reg0',
                 gpio_name='SEG_axi_gpio_video_Reg'):
        """Returns a new instance of an HDMI object. 
        
        Assign the given frame buffer if specified, otherwise create a new 
        frame buffer. The parameter `frame_list` is optional.
        
        Supported video modes are:
        1920x1080, 60Hz: VMODE_1920x1080  = 4;
        1280x1024, 60Hz: VMODE_1280x1024  = 3;
        1280x720, 60Hz:  VMODE_1280x720   = 2;
        800x600, 60Hz:   VMODE_800x600    = 1;
        640x480, 60Hz:   VMODE_640x480    = 0 (default)
        
        Default timeout is 10s. Timeout is ignored for HDMI OUT.
        
        Note
        ----
        HDMI supports direction 'in' and 'out'.
        
        Parameters
        ----------
        direction : str
            Can be 'in' for HDMI IN or 'out' for HDMI OUT.
        frame_list : _framebuffer, optional
            A frame buffer storing at most 3 frames.
        video_mode : int
            Video mode for HDMI OUT. Ignored for HDMI IN.
        init_timeout : int, optional
            Timeout in seconds for HDMI IN initialization.
        vdma_name : str
            The name of the video DMA that is available in PL ip_dict.
        display_name : str
            The name of the video display IP that is available in PL ip_dict.
        capture_name : str
            The name of the video capture IP that is available in PL ip_dict.
        clk_name : str
            The name of the clock segment that is available in PL ip_dict.
        gpio_name : str
            The name of the GPIO segment that is available in PL ip_dict.
            
        """
        if not direction.lower() in ['in', 'out']:
            raise ValueError("HDMI direction should be in or out.")
        if (not isinstance(frame_list, _video._frame)) and \
                (not frame_list is None):
            raise ValueError("frame_list should be of type _video._frame.")
        if (not isinstance(init_timeout, int)) or init_timeout < 1:
            raise ValueError("init_timeout should be integer >= 1.")

        if vdma_name not in PL.ip_dict:
            raise LookupError("No such VDMA in the overlay.")
        if display_name not in PL.ip_dict:
            raise LookupError("No such display address in the overlay.")
        if capture_name not in PL.ip_dict:
            raise LookupError("No such capture address in the overlay.")
        if clk_name not in PL.ip_dict:
            raise LookupError("No such clock address in the overlay.")
        if gpio_name not in PL.ip_dict:
            raise LookupError("No such GPIO in the overlay.")

        vdma_dict = {
            'BASEADDR': PL.ip_dict[vdma_name][0],
            'NUM_FSTORES': 3,
            'INCLUDE_MM2S': 1,
            'INCLUDE_MM2S_DRE': 0,
            'M_AXI_MM2S_DATA_WIDTH': 32,
            'INCLUDE_S2MM': 1,
            'INCLUDE_S2MM_DRE': 0,
            'M_AXI_S2MM_DATA_WIDTH': 32,
            'INCLUDE_SG': 0,
            'ENABLE_VIDPRMTR_READS': 1,
            'USE_FSYNC': 1,
            'FLUSH_ON_FSYNC': 1,
            'MM2S_LINEBUFFER_DEPTH': 4096,
            'S2MM_LINEBUFFER_DEPTH': 4096,
            'MM2S_GENLOCK_MODE': 0,
            'S2MM_GENLOCK_MODE': 0,
            'INCLUDE_INTERNAL_GENLOCK': 1,
            'S2MM_SOF_ENABLE': 1,
            'M_AXIS_MM2S_TDATA_WIDTH': 24,
            'S_AXIS_S2MM_TDATA_WIDTH': 24,
            'ENABLE_DEBUG_INFO_1': 0,
            'ENABLE_DEBUG_INFO_5': 0,
            'ENABLE_DEBUG_INFO_6': 1,
            'ENABLE_DEBUG_INFO_7': 1,
            'ENABLE_DEBUG_INFO_9': 0,
            'ENABLE_DEBUG_INFO_13': 0,
            'ENABLE_DEBUG_INFO_14': 1,
            'ENABLE_DEBUG_INFO_15': 1,
            'ENABLE_DEBUG_ALL': 0,
            'ADDR_WIDTH': 32,
        }
        vtc_display_addr = PL.ip_dict[display_name][0]
        vtc_capture_addr = PL.ip_dict[capture_name][0]
        dyn_clk_addr = PL.ip_dict[clk_name][0]
        gpio_dict = {
            'BASEADDR': PL.ip_dict[gpio_name][0],
            'INTERRUPT_PRESENT': 1,
            'IS_DUAL': 1,
        }

        self.direction = direction.lower()
        if self.direction == 'out':
            # HDMI output
            if frame_list is None:
                self._display = _video._display(vdma_dict,
                                                vtc_display_addr,
                                                dyn_clk_addr, 1)
                self._display.mode(video_mode)
            else:
                self._display = _video._display(vdma_dict,
                                                vtc_display_addr,
                                                dyn_clk_addr, 1,
                                                frame_list)
                self._display.mode(video_mode)
                                                
            self.frame_list = self._display.framebuffer
            
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
            
            0 : '640x480, 60Hz'
            
            1 : '800x600, 60Hz'
            
            2 : '1280x720, 60Hz'
            
            3 : '1280x1024, 60Hz'
            
            4 : '1920x1080, 60Hz'
            
            If `new_mode` is not specified, return the current mode.
            
            Parameters
            ----------
            new_mode : int
                A mode index from 0 to 4.
                
            Returns
            -------
            str
                The resolution of the display.
                
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
            i : int, optional
                A location in the bytearray.
            new_frame: bytearray, optional
                A bytearray used to overwrite the frame.
                
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
            index : int, optional
                Index of the frames, from 0 to 2.
            new_frame : Frame, optional
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
            new_frame_index : int, optional
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
            
            self.frame_addr = self._display.frame_addr
            """Get the current frame address.
            
            Parameters
            ----------
            i : int, optional
                Index of the current frame buffer.
            
            Returns
            -------
            int
                Address of the frame, thus current frame buffer.
                
            """
            
            self.frame_phyaddr = self._display.frame_phyaddr
            """Get the current physical frame address.
            
            Parameters
            ----------
            i : int, optional
                Index of the current frame buffer.
            
            Returns
            -------
            int
                Physical address of the frame, thus current frame buffer.
                
            """
            
        else:
            # HDMI input
            if frame_list is None:
                self._capture = _video._capture(vdma_dict,
                                                gpio_dict,
                                                vtc_capture_addr,
                                                init_timeout)
            else:
                self._capture = _video._capture(vdma_dict,
                                                gpio_dict,
                                                vtc_capture_addr,
                                                init_timeout,
                                                frame_list)
                                                
            self.frame_list = self._capture.framebuffer
            
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
            i : int, optional
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
            index : int, optional
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
            new_frame_index : int, optional
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
            
            self.frame_addr = self._capture.frame_addr
            """Get the current frame address.
            
            Parameters
            ----------
            i : int, optional
                Index of the current frame buffer.
            
            Returns
            -------
            int
                Address of the frame, thus current frame buffer.
                
            """
            
            self.frame_phyaddr = self._capture.frame_phyaddr
            """Get the current physical frame address.
            
            Parameters
            ----------
            i : int, optional
                Index of the current frame buffer.
            
            Returns
            -------
            int
                Physical address of the frame, thus current frame buffer.
                
            """
            
    def start(self,timeout=20):
        """Start the video controller.
            
        Parameters
        ----------
        timeout : int, optional
            HDMI controller response timeout in seconds.
        
        Returns
        -------
        None
        
        """
        if timeout<=0:
            raise ValueError("timeout must be greater than 0.")
            
        while self.state() != 1:
            try:
                self._capture.start()
            except Exception as err:
                if timeout > 0:
                    sleep(1)
                    timeout -= 1
                else:
                    raise err
                    
    def _frame_out(self, *args):
        """Returns the specified frame or the active frame.
        
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
                        
    def _frame_in(self, index=None):
        """Returns the specified frame or the active frame.
        
        Parameters
        ----------
        index : int, optional
            The index of a frame in the frame buffer, from 0 to 2.
            
        Returns
        -------
        Frame
            An object of a frame in the frame buffer.
            
        """
        if index is None:
            buf = self._capture.frame()
        else:
            buf = self._capture.frame(index)
        return Frame(self.frame_width(), self.frame_height(), buf)
        
    def __del__(self):
        """Delete the HDMI object.
        
        Stop the video controller first to avoid odd behaviors of the DMA.
        
        Returns
        -------
        None
        
        """
        if hasattr(self, 'stop'):
            self.stop()
        if hasattr(self, '_capture'):
            del self._capture
        elif hasattr(self, '_display'):
            del self._display
            
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
            self._framebuffer = _video._frame(1)
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
        The original frame stores pixels as (b,g,r). Hence, to return a tuple 
        (r,g,b), we need to return (self.frame[offset+2], self.frame[offset+1],
        self.frame[offset]).
            
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
            offset = 3 * (y * MAX_FRAME_WIDTH + x)
            return self.frame[offset+2],self.frame[offset+1],\
                    self.frame[offset]
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
        The original frame stores pixels as (b,g,r).
        
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
            offset = 3 * (y * MAX_FRAME_WIDTH + x)
            self.frame[offset + 2] = value[0]
            self.frame[offset + 1] = value[1]
            self.frame[offset] = value[2]
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
            
    def save_as_jpeg(self, path, width=None, height=None):
        """Save a video frame to a JPEG image.
        
        Note
        ----
        The JPEG filename must be included in the path.
        
        Parameters
        ----------
        path : str
            The path where the JPEG will be saved.
        width : int
            The width of the frame.
        height : int
            The height of the frame.
            
        Returns
        -------
        None
        
        """
        if width is None:
            width = self.width
        if height is None:
            height = self.height
        np_frame = (np.frombuffer(self.frame, dtype=np.uint8)). \
                      reshape(MAX_FRAME_HEIGHT, MAX_FRAME_WIDTH, 3)\
                        [:height, :width, 2::-1]
        image = Image.fromarray(np_frame)
        image.save(path, 'JPEG')
