#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from . import Arduino
from . import ARDUINO_GROVE_I2C




ARDUINO_GROVE_OLED_PROGRAM = "arduino_grove_oled.bin"
CONFIG_IOP_SWITCH = 0x1
SET_NORMAL_DISPLAY = 0x3
SET_INVERSE_DISPLAY = 0x5
SET_GRAY_LEVEL = 0x7
SET_PAGE_MODE = 0x9
SET_HORIZONTAL_MODE = 0xB
SET_TEXT_XY = 0xD
CLEAR_DISPLAY = 0xF
SET_CONTRAST_LEVEL = 0x11
PUT_STRING = 0x13
SET_HORIZONTAL_SCROLL = 0x15
ENABLE_SCROLL = 0x17
DISABLE_SCROLL = 0x19


class Grove_OLED(object):
    """This class controls the Grove IIC OLED.

    Grove LED 128x64 Display module is an OLED monochrome 128x64 matrix
    display module. Model: OLE35046P. Hardware version: v1.1.

    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove OLED object. 
        
        Note
        ----
        The parameter `gr_pin` is a list organized as [scl_pin, sda_pin].
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.
            
        """
        if gr_pin not in [ARDUINO_GROVE_I2C]:
            raise ValueError("Group number can only be I2C.")

        self.microblaze = Arduino(mb_info, ARDUINO_GROVE_OLED_PROGRAM)

        self.set_horizontal_mode()
        self.clear()

    def write(self, text):
        """Write a new text string on the OLED.
        
        Clear the screen first to correctly show the new text.

        Parameters
        ----------
        text : str
            The text string to be displayed on the OLED screen.
            
        Returns
        -------
        None
        
        """
        # First write length, then write rest of string
        data = [len(text)]
        data += [ord(char) for char in text]
        self.microblaze.write_mailbox(0, data)

        # Finally write the print string command
        self.microblaze.write_blocking_command(PUT_STRING)

    def clear(self):
        """Clear the OLED screen.
        
        This is done by writing empty strings into the OLED in Microblaze.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(CLEAR_DISPLAY)

    def set_position(self, row, column):
        """Set the position of the display.
        
        The position is indicated by (row, column).
        
        Parameters
        ----------
        row : int
            The row number to start the display.
        column : int
            The column number to start the display.
        
        Returns
        -------
        None
        
        """
        # First write row and column positions
        self.microblaze.write_mailbox(0, [row, column])

        # Then write the command
        self.microblaze.write_blocking_command(SET_TEXT_XY)

    def set_normal_mode(self):
        """Set the display mode to normal.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(SET_NORMAL_DISPLAY)

    def set_inverse_mode(self):
        """Set the display mode to inverse.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(SET_INVERSE_DISPLAY)

    def set_page_mode(self):
        """Set the display mode to paged.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(SET_PAGE_MODE)

    def set_horizontal_mode(self):
        """Set the display mode to horizontal.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(SET_HORIZONTAL_MODE)

    def set_contrast(self, brightness):
        """Set the contrast level for the OLED display.
        
        The contrast level is in [0, 255].
        
        Parameters
        ----------
        brightness : int
            The brightness of the display.
        
        Returns
        -------
        None
        
        """
        # First write the brightness
        if brightness not in range(0, 256):
            raise ValueError("Valid brightness is between 0 and 255.")
        self.microblaze.write_mailbox(0, brightness)

        # Then write the command
        self.microblaze.write_blocking_command(SET_CONTRAST_LEVEL)


