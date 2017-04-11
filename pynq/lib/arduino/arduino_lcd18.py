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

__author__      = "Parimal Patel, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import asyncio
import os
from PIL import Image
from numpy import array
from pynq import MMIO
from pynq import Xlnk
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import ARDUINO

ARDUINO_LCD18_PROGRAM = "arduino_lcd18.bin"

def _convert_color(color):
    """Convert a 24-bit color to 16-bit.

    The input `color` is assumed to be a 3-component list [R,G,B], each with
    8 bits for color level.

    This method will translate that list of colors into a 16-bit number,
    with first 5 bits indicating R component,
    last 5 bits indicating B component, and remaining
    6 bits in the middle indicating G component.
    i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).

    """
    for i in color:
        if i not in range(256):
            raise ValueError("Valid color value for R, G, B is 0 - 255.")
    red, green, blue = color
    return ((blue & 0xF8) << 8) | ((green & 0xFC) << 3) | ((red & 0xF8) >> 3)

class Arduino_LCD18(object):
    """This class controls the Adafruit 1.8" LCD shield from AdaFruit. 
    
    The LCD panel consists of ST7735 LCD controller, a joystick, and a microSD
    socket. This class uses the LCD panel (128x160 pixels) and the joystick. 
    The joystick uses A3 analog channel. https://www.adafruit.com/product/802.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Arduino_LCD18.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    buf_manager : Xlnk
        DDR management unit that provides the physical address of the image.
        
    """
    def __init__(self, if_id):
        """Return a new instance of an Arduino_LCD18 object.
        
        Parameters
        ----------
        if_id : int
            The interface ID (3) corresponding to (ARDUINO).
            
        """
        if not if_id in [ARDUINO]:
            raise ValueError("No such IOP for Arduino LCD device.")

        self.iop = request_iop(if_id, ARDUINO_LCD18_PROGRAM)
        self.mmio = self.iop.mmio
        self.buf_manager = Xlnk()
        self.iop.start()

    def clear(self):
        """Clear the screen.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET+
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def display(self, img_path, x_pos = 0, y_pos = 127, orientation = 3,
                background = None, frames = 1):
        """Animate the image at the desired location for multiple frames.

        The maximum screen resolution is 160x128.

        Users can specify the position to display the image. For example, to
        display the image in the center, `x_pos` can be (160-`width`/2),
        `y_pos` can be (128/2)+(`height`/2).

        A typical orientation is 3. The origin of orientation 0, 1, 2, and 3
        corresponds to upper right corner, lower right corner, lower left
        corner, and upper left corner, respectively. Currently, only 1 and 3
        are valid orientations. If users choose orientation 1, the picture
        will be shown upside-down. If users choose orientation 3, the picture
        will be shown consistently with the LCD screen orientation.

        Parameter `background` specifies the color of the background;
        it is a list of 3 elements: R, G, and B, each with 8 bits for color
        level.

        Parameters
        ----------
        img_path : str
            The file path to the image stored in the file system.
        x_pos : int
            x position of a pixel where the image starts.
        y_pos : int
            y position of a pixel where the image starts.
        background : list
            A list of [R, G, B] components for background, each of 8 bits.
        orientation : int
            orientation of the image; valid values are 1 and 3.
        frames : int
            Number of frames the image is moved, must be less than 65536.

        Returns
        -------
        None

        """
        task = asyncio.ensure_future(
                    self.display_async(img_path, x_pos, y_pos, orientation,
                                  background, frames))
        loop = asyncio.get_event_loop()
        loop.run_until_complete(task)

    @asyncio.coroutine
    def display_async(self, img_path, x_pos=0, y_pos=127,
                orientation=3, background=None, frames=1):
        """Animate the image at the desired location for multiple frames.

        The maximum screen resolution is 160x128.

        Users can specify the position to display the image. For example, to
        display the image in the center, `x_pos` can be (160-`width`/2),
        `y_pos` can be (128/2)+(`height`/2).

        A typical orientation is 3. The origin of orientation 0, 1, 2, and 3
        corresponds to upper right corner, lower right corner, lower left
        corner, and upper left corner, respectively. Currently, only 1 and 3
        are valid orientations. If users choose orientation 1, the picture
        will be shown upside-down. If users choose orientation 3, the picture
        will be shown consistently with the LCD screen orientation.

        Parameter `background` specifies the color of the background;
        it is a list of 3 elements: R, G, and B, each with 8 bits for color
        level.

        Parameters
        ----------
        img_path : str
            The file path to the image stored in the file system.
        x_pos : int
            x position of a pixel where the image starts.
        y_pos : int
            y position of a pixel where the image starts.
        background : list
            A list of [R, G, B] components for background, each of 8 bits.
        orientation : int
            orientation of the image; valid values are 1 and 3.
        frames : int
            Number of frames the image is moved, must be less than 65536.

        Returns
        -------
        None

        """
        if not x_pos in range(160):
            raise ValueError("Valid x_pos is 0 - 159.")
        if not y_pos in range(128):
            raise ValueError("Valid y_pos is 0 - 127.")
        if not orientation in [1,3]:
            raise ValueError("Valid orientation is 1 or 3.")
        if not frames in range(1,65536):
            raise ValueError("Valid number of frames is 1 - 65535.")
        if not os.path.isfile(img_path):
            raise ValueError("Specified image file does not exist.")

        if background is None:
            background = [0,0,0]
        background16 = _convert_color(background)

        image_file = Image.open(img_path)
        width, height = image_file.size
        if not width in range(161) or not height in range(129):
            raise ValueError("Picture too large to be fit in 160x128 screen.")
        image_file.resize((width, height), Image.ANTIALIAS)
        image_array = array(image_file)
        image_file.close()

        file_size = width * height * 2
        buf0 = self.buf_manager.cma_alloc(file_size, data_type="uint8_t")
        buf1 = self.buf_manager.cma_get_buffer(buf0, file_size)
        phy_addr = self.buf_manager.cma_get_phy_addr(buf0)
        try:
            for j in range(width):
                for i in range(height):
                    red, green, blue = image_array[i][j]
                    temp = ((blue & 0xF8) << 8) | ((green & 0xFC) << 3) | \
                           ((red & 0xF8) >> 3)
                    index = 2 * ((height - i - 1) * width + j)
                    buf1[index] = bytes([temp & 0xFF])
                    buf1[index + 1] = bytes([(temp & 0xFF00) >> 8])

            self.mmio.write(iop_const.MAILBOX_OFFSET, x_pos)
            self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_pos)
            self.mmio.write(iop_const.MAILBOX_OFFSET+8, width)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, height)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, phy_addr)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x14, background16)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x18, orientation)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x1c, frames)
            # Ensure interrupt is reset before issuing command
            if self.iop.interrupt:
                self.iop.interrupt.clear()
            self.mmio.write(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
            while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
                if self.iop.interrupt:
                    yield from self.iop.interrupt.wait()
        finally:
            if self.iop.interrupt:
                self.iop.interrupt.clear()
            self.buf_manager.cma_free(buf0)

    def draw_line(self,x_start_pos,y_start_pos,x_end_pos,y_end_pos,
                  color=None,background=None,orientation=3):
        """Draw a line from starting point to ending point.

        The maximum screen resolution is 160x128.

        Parameter `color` specifies the color of the line; it is a list of 3
        elements: R, G, and B, each with 8 bits for color level.

        Parameter `background` is similar to parameter `color`, except that it
        specifies the background color.

        A typical orientation is 3. The origin of orientation 0, 1, 2, and 3
        corresponds to upper right corner, lower right corner, lower left
        corner, and upper left corner, respectively. Currently, only 1 and 3
        are valid orientations. If users choose orientation 1, the picture
        will be shown upside-down. If users choose orientation 3, the picture
        will be shown consistently with the LCD screen orientation.

        Parameters
        ----------
        x_start_pos : int
            x position (in pixels) where the line starts.
        y_start_pos : int
            y position (in pixels) where the line starts.
        x_end_pos : int
            x position (in pixels ) where the line ends.
        y_end_pos : int
            y position (in pixels) where the line ends.
        color : list
            A list of [R, G, B] components for line color, each of 8 bits.
        background : list
            A list of [R, G, B] components for background, each of 8 bits.
        orientation : int
            orientation of the image; valid values are 1 and 3.

        Returns
        -------
        None

        """
        if not x_start_pos in range(160):
            raise ValueError("Valid x start position is 0 - 159.")
        if not y_start_pos in range(128):
            raise ValueError("Valid y start position is 0 - 127.")
        if not x_end_pos in range(160):
            raise ValueError("Valid x end position is 0 - 159.")
        if not y_end_pos in range(128):
            raise ValueError("Valid y end position is 0 - 127.")
        if not orientation in [1,3]:
            raise ValueError("Valid orientation is 1 or 3.")

        if color is None:
            color = [255,255,255]
        color16 = _convert_color(color)
        if background is None:
            background = [0,0,0]
        background16 = _convert_color(background)

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+8, x_end_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, y_end_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, color16)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x14, background16)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x18, orientation)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def print_string(self,x_start_pos,y_start_pos,text,
                     color=None,background=None,orientation=3):
        """Draw a character with a specific color.

        The maximum screen resolution is 160x128.

        Parameter `color` specifies the color of the text; it is a list of 3
        elements: R, G, and B, each with 8 bits for color level.

        Parameter `background` is similar to parameter `color`, except that it
        specifies the background color.

        A typical orientation is 3. The origin of orientation 0, 1, 2, and 3
        corresponds to upper right corner, lower right corner, lower left
        corner, and upper left corner, respectively. Currently, only 1 and 3
        are valid orientations. If users choose orientation 1, the picture
        will be shown upside-down. If users choose orientation 3, the picture
        will be shown consistently with the LCD screen orientation.
        
        Parameters
        ----------
        x_start_pos : int
            x position (in pixels) where the line starts.
        y_start_pos : int
            y position (in pixels) where the line starts.
        text : str
            printable ASCII characters.
        color : list
            A list of [R, G, B] components for line color, each of 8 bits.
        background : list
            A list of [R, G, B] components for background, each of 8 bits.
        orientation : int
            orientation of the image; valid values are 1 and 3.

        Returns
        -------
        None

        """
        if not x_start_pos in range(160):
            raise ValueError("Valid x start position is 0 - 159.")
        if not y_start_pos in range(128):
            raise ValueError("Valid y start position is 0 - 127.")
        if not type(text) is str:
            raise ValueError("Character has to be of string type.")
        if not orientation in [1,3]:
            raise ValueError("Valid orientation is 1 or 3.")

        if color is None:
            color = [255,255,255]
        color16 = _convert_color(color)
        if background is None:
            background = [0,0,0]
        background16 = _convert_color(background)

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 8, color16)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 0xc, background16)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 0x10, orientation)

        temp_txt = text
        count = len(text)
        for _ in range(count % 4):
            temp_txt = temp_txt + str('\0')

        temp = 0
        for i in range(len(temp_txt)):
            temp = temp | (ord(temp_txt[i]) << 8 * (i % 4))
            if i % 4 == 3:
                self.mmio.write(iop_const.MAILBOX_OFFSET + 0x14 + i - 3, temp)
                temp = 0

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            
    def draw_filled_rectangle(self,x_start_pos,y_start_pos,width,height,
                              color=None, background=None, orientation=3):
        """Draw a filled rectangle.

        Parameter `color` specifies the color of the text; it is a list of 3
        elements: R, G, and B, each with 8 bits for color level.

        Parameter `background` is similar to parameter `color`, except that it
        specifies the background color.

        A typical orientation is 3. The origin of orientation 0, 1, 2, and 3
        corresponds to upper right corner, lower right corner, lower left
        corner, and upper left corner, respectively. Currently, only 1 and 3
        are valid orientations. If users choose orientation 1, the picture
        will be shown upside-down. If users choose orientation 3, the picture
        will be shown consistently with the LCD screen orientation.

        Parameters
        ----------
        x_start_pos : int
            x position (in pixels) where the rectangle starts.
        y_start_pos : int
            y position (in pixels) where the rectangle starts.
        width : int
            Width of the rectangle (in pixels).
        height : int
            Height of the rectangle (in pixels).
        color : list
            A list of [R, G, B] components for line color, each of 8 bits.
        background : list
            A list of [R, G, B] components for background, each of 8 bits.
        orientation : int
            orientation of the image; valid values are 1 and 3.

        Returns
        -------
        None

        """
        if not x_start_pos in range(160):
            raise ValueError("Valid x start position is 0 - 159.")
        if not y_start_pos in range(128):
            raise ValueError("Valid y start position is 0 - 127.")
        if not width in range(160):
            raise ValueError("Valid x end position is 0 - 159.")
        if not height in range(128):
            raise ValueError("Valid y end position is 0 - 127.")
        if not orientation in [1,3]:
            raise ValueError("Valid orientation is 1 or 3.")

        if color is None:
            color = [255,255,255]
        color16 = _convert_color(color)
        if background is None:
            background = [0,0,0]
        background16 = _convert_color(background)

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+8, width)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, height)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, color16)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x14, background16)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x18, orientation)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xb)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def read_joystick(self):
        """Read the joystick values.

        The joystick values can be read when user is pressing the button
        toward a specific direction.

        The returned values can be:
        1: left;
        2: down;
        3: center;
        4: right;
        5: up;
        0: no button pressed.

        Returns
        -------
        int
            Indicating the direction towards which the button is pushed.

        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xd)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(iop_const.MAILBOX_OFFSET)
        