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


import os
from PIL import Image
from numpy import array
from pynq import MMIO
from pynq import Xlnk
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import ARDUINO

ARDUINO_LCD18_PROGRAM = "arduino_lcd18.bin"

class Arduino_LCD18(object):
    """This class controls the Adafruit 1.8" LCD shield from AdaFruit. 
    
    The LCD panel consists of ST7735 LCD controller, a joystick, and a microSD
    socket. This class uses the LCD panel (128x160 pixels) and the joystick. 
    The joystick uses A3 analog channel.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Arduino_LCD18.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    xlnk : Xlnk
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
        self.xlnk = Xlnk()
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

    def display(self,img_path,
                x_pos=0,y_pos=127,orientation=3,background=0):
        """Display a image at the desired location.

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

        The background color is indicated by the parameter `background`:
        0: BLACK;
        1: BLUE;
        2: RED;
        3: GREEN;
        4: CYAN;
        5: MAGENTA;
        6: YELLOW;
        7: WHITE;
        8: PINK.

        Parameters
        ----------
        img_path : str
            The file path to the image stored in the file system.
        x_pos : int
            x position of a pixel where the image starts.
        y_pos : int
            y position of a pixel where the image starts.
        orientation : int
            orientation of the image; valid values are 1 and 3.
        background : int
            Background color, specified by a number from 0 to 8.

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
        if not background in range(9):
            raise ValueError("Valid background color is 0 - 8.")
        if not os.path.isfile(img_path):
            raise ValueError("Specified image file does not exist.")

        image_file = Image.open(img_path)
        width, height = image_file.size
        if not width in range(161) or not height in range(129):
            raise ValueError("Picture too large to be fit in 160x128 screen.")
        image_file.resize((width, height), Image.ANTIALIAS)
        image_array = array(image_file)
        image_file.close()

        file_size = width * height * 2
        buf0 = self.xlnk.cma_alloc(file_size, data_type="uint8_t")
        buf1 = self.xlnk.cma_get_buffer(buf0, file_size)
        phy_addr = self.xlnk.cma_get_phy_addr(buf0)
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
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, orientation)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x14, phy_addr)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x18, background)

            self.mmio.write(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
            while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
                pass
        finally:
            self.xlnk.cma_free(buf0)
                      
    def animate(self,img_path,frames,
                x_pos=0,y_pos=127,orientation=3,background=0):
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

        The background color is indicated by the parameter `background`:
        0: BLACK;
        1: BLUE;
        2: RED;
        3: GREEN;
        4: CYAN;
        5: MAGENTA;
        6: YELLOW;
        7: WHITE;
        8: PINK.

        Parameters
        ----------
        img_path : str
            The file path to the image stored in the file system.
        frames : int
            Number of frames the image is moved, must be less than 65536.
        x_pos : int
            x position of a pixel where the image starts.
        y_pos : int
            y position of a pixel where the image starts.
        orientation : int
            orientation of the image; valid values are 1 and 3.
        background : int
            Background color, specified by a number from 0 to 8.

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
        if not frames in range(65536):
            raise ValueError("Valid number of frames is 0 - 65535.")
        if not background in range(9):
            raise ValueError("Valid background color is 0 - 8.")
        if not os.path.isfile(img_path):
            raise ValueError("Specified image file does not exist.")

        image_file = Image.open(img_path)
        width, height = image_file.size
        if not width in range(161) or not height in range(129):
            raise ValueError("Picture too large to be fit in 160x128 screen.")
        image_file.resize((width, height), Image.ANTIALIAS)
        image_array = array(image_file)
        image_file.close()

        file_size = width * height * 2
        buf0 = self.xlnk.cma_alloc(file_size, data_type="uint8_t")
        buf1 = self.xlnk.cma_get_buffer(buf0, file_size)
        phy_addr = self.xlnk.cma_get_phy_addr(buf0)
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
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, orientation)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x14, phy_addr)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x18, frames)
            self.mmio.write(iop_const.MAILBOX_OFFSET+0x1c, background)

            self.mmio.write(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
            while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
                pass
        finally:
            self.xlnk.cma_free(buf0)

    def draw_line(self,x_start_pos,y_start_pos,x_end_pos,y_end_pos,color):
        """Draw a line from starting point to ending point.

        The maximum screen resolution is 160x128.

        Parameter `color` specifies the color of the line; it is 16-bit, with
        first 5 bits indicating R component, last 5 bits indicating B
        component, and remaining 6 bits in the middle indicating G component.
        i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).

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
        color : int
            A number less than 65536 specifying the line color.

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
        if not color in range(65536):
            raise ValueError("Valid color is 0 - 65535.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+8, x_end_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, y_end_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, color)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def draw_horizontal_line(self,x_start_pos,y_start_pos,length,color):
        """Draw a horizontal line.

        The maximum screen resolution is 160x128.

        Parameter `color` specifies the color of the line; it is 16-bit, with
        first 5 bits indicating R component, last 5 bits indicating B
        component, and remaining 6 bits in the middle indicating G component.
        i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).

        Parameters
        ----------
        x_start_pos : int
            x position (in pixels) where the line starts.
        y_start_pos : int
            y position (in pixels) where the line starts.
        length : int
            length in pixels.
        color : int
            A number less than 65536 specifying the line color.

        Returns
        -------
        None

        """
        if not x_start_pos in range(160):
            raise ValueError("Valid x start position is 0 - 159.")
        if not y_start_pos in range(128):
            raise ValueError("Valid y start position is 0 - 127.")
        if not length in range(160):
            raise ValueError("Valid length is 0 - 159.")
        if not color in range(65536):
            raise ValueError("Valid color is 0 - 65535.")
            
        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+8, length)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, color)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xb)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def draw_vertical_line(self,x_start_pos,y_start_pos,length,color):
        """Draw a vertical line

        The maximum screen resolution is 160x128.

        Parameter `color` specifies the color of the line; it is 16-bit, with
        first 5 bits indicating R component, last 5 bits indicating B
        component, and remaining 6 bits in the middle indicating G component.
        i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).

        Parameters
        ----------
        x_start_pos : int
            x position (in pixels) where the line starts.
        y_start_pos : int
            y position (in pixels) where the line starts.
        length : int
            length in pixels.
        color : int
            A number less than 65536 specifying the line color.

        Returns
        -------
        None

        """
        if not x_start_pos in range(160):
            raise ValueError("Valid x start position is 0 - 159.")
        if not y_start_pos in range(128):
            raise ValueError("Valid y start position is 0 - 127.")
        if not length in range(128):
            raise ValueError("Valid length is 0 - 127.")
        if not color in range(65536):
            raise ValueError("Valid color is 0 - 65535.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+8, length)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, color)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xd)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def print_scaled(self,x_start_pos,y_start_pos,char,color,background,size):
        """Draw a character with a specific color and specific size.

        The maximum screen resolution is 160x128.

        Parameter `color` and `background` specifies the color of the text and
        background, respectively; they are 16-bit each, with
        first 5 bits indicating R component, last 5 bits indicating B
        component, and remaining 6 bits in the middle indicating G component.
        i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).
        
        Parameters
        ----------
        x_start_pos : int
            x position (in pixels) where the line starts
        y_start_pos : int
            y position (in pixels) where the line starts
        char : str
            printable ASCII character
        color : int
            A number less than 65536 specifying the text color.
        background : int
            A number less than 65536 specifying the background color.
        size : int
            Character size, multiple of standard character size (at most 3).

        Returns
        -------
        None

        """
        if not x_start_pos in range(160):
            raise ValueError("Valid x start position is 0 - 159.")
        if not y_start_pos in range(128):
            raise ValueError("Valid y start position is 0 - 127.")
        if not type(char) is str:
            raise ValueError("Character has to be of string type.")
        if not color in range(65536):
            raise ValueError("Valid text color is 0 - 65535.")
        if not background in range(65536):
            raise ValueError("Valid text background color is 0 - 65535.")
        if not size in range(4):
            raise ValueError("Valid scaled size is 0 - 3.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+8, ord(char[0]))
        self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, color)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, background)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x14, size)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xf)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def set_cursor(self,x_pos,y_pos):
        """Move cursor to the specified location.

        The maximum screen resolution is 160x128.

        Parameters
        ----------
        x_pos : int
            cursor's x position (in pixels).
        y_pos : int
            cursor's y position (in pixels).

        Returns
        -------
        None

        """
        if not x_pos in range(160):
            raise ValueError("Valid pixel's x position is 0 - 159.")
        if not y_pos in range(128):
            raise ValueError("Valid pixel's y position is 0 - 127.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_pos)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x11)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def set_color(self,color):
        """Set the current color.

        Parameter `color` specifies the color of the line; it is 16-bit, with
        first 5 bits indicating R component, last 5 bits indicating B
        component, and remaining 6 bits in the middle indicating G component.
        i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).

        Parameters
        ----------
        color : int
            A number less than 65536 specifying the color.

        Returns
        -------
        None

        """
        if not color in range(65536):
            raise ValueError("Valid text color is 0 - 65535.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, color)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x13)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
         
    def print_char(self,char):
        """Draw a character.

        The character will be printed at the current position with the current
        color.
        
        Parameters
        ----------
        char : str
            printable ASCII character.

        Returns
        -------
        None

        """
        if not type(char) is str:
            raise ValueError("Character has to be of string type.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, ord(char[0]))

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x15)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def print_string(self,txt):
        """Draw a null-terminated string.

        The string will be printed at the current position with the current
        color.
        
        Parameters
        ----------
        txt : str
            printable null-terminated string.

        Returns
        -------
        None

        """
        if not type(txt) is str:
            raise ValueError("Input text has to be of string type.")

        temp_txt = txt
        count = len(txt)
        for _ in range(count%4):
            temp_txt = temp_txt + str('\0')

        temp=0
        for i in range(len(temp_txt)):
            temp=temp | (ord(temp_txt[i]) << 8*(i%4))
            if i%4==3:
                self.mmio.write(iop_const.MAILBOX_OFFSET+i-3, temp)
                temp=0

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x17)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            
    def draw_filled_rectangle(self,x_start_pos,y_start_pos,width,height,color):
        """Draw a filled rectangle.

        Parameter `color` specifies the color of the line; it is 16-bit, with
        first 5 bits indicating R component, last 5 bits indicating B
        component, and remaining 6 bits in the middle indicating G component.
        i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).
        
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
        color : int
            A number less than 65536 specifying the color.

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
        if not color in range(65536):
            raise ValueError("Valid color is 0 - 65535.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, x_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, y_start_pos)
        self.mmio.write(iop_const.MAILBOX_OFFSET+8, width)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0xc, height)
        self.mmio.write(iop_const.MAILBOX_OFFSET+0x10, color)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x19)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def print_unsigned(self,number):
        """Print an unsigned 16-bit number.
        
        Parameters
        ----------
        number : int
            16-bit unsigned number (less than 65536).

        Returns
        -------
        None

        """
        if not number in range(65536):
            raise ValueError("Valid number is 0 - 65535.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, number)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1b)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def set_orientation(self,orientation):
        """Set orientation.

        A typical orientation is 3. The origin of orientation 0, 1, 2, and 3
        corresponds to upper right corner, lower right corner, lower left
        corner, and upper left corner, respectively. Currently, only 1 and 3
        are valid orientations. If users choose orientation 1, the picture
        will be shown upside-down. If users choose orientation 3, the picture
        will be shown consistently with the LCD screen orientation.

        Parameters
        ----------
        orientation : int
            Display orientation. Valid values are 1 and 3.

        Returns
        -------
        None

        """
        if not orientation in [1,3]:
            raise ValueError("Valid orientation is 1 or 3.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, orientation)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1d)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def set_background(self,color):
        """Set background color.

        Parameter `color` specifies the color of the line; it is 16-bit, with
        first 5 bits indicating R component, last 5 bits indicating B
        component, and remaining 6 bits in the middle indicating G component.
        i.e., 16-bit color -> (5 bits, 6 bits, 5 bits) -> (R,G,B).

        Parameters
        ----------
        color : int
            A number less than 65536 specifying the text color.

        Returns
        -------
        None

        """
        if not color in range(65536):
            raise ValueError("Valid background color is 0 - 65535.")

        self.mmio.write(iop_const.MAILBOX_OFFSET, color)

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1f)
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
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x31)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(iop_const.MAILBOX_OFFSET)
        