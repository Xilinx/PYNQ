__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

import numpy as np
from PIL import Image
from . import _video
from pynq import Xlnk


class FrameBuffer(object):
    """This class manages a framebuffer, or image frames. It exposes a
    python friendly bytearray that uses can manipulate and exposes
    the physical address that can be passed to an FPGA

    Attributes
    ----------
    width : int
        The width of the frame.
    height : int
        The height of the frame.
    color_depth : int
        The number of bytes per pixel (usually 3 for RGB)

    """
    def __init__(self, width, height, color_depth = 3):
        """Returns a new FrameBuffer object.

        Parameters
        ----------
        width : int
            The width of a frame.
        height : int
            The height of a frame.
        color_depth : int
            The number of bytes per pixel (usually 3 for RGB)

        """


        self.xlnk = Xlnk()

        self.__width = width
        self.__height = height
        self.__color_depth = color_depth
        self.frame = _video._framebuffer(width, height, color_depth)
        #size = self.width * self.height * self.color_depth
        #self.frame = self.xlnk.cma_alloc(size)

    def get_phy_address(self):
        """Returns the physical address of the buffer.

        They physical address is within the kernel memory
        space that can be read by and written to using the FPGA.

        This address cannot be used by user application, instead user
        applications need virtual memory.

        This address should be passed to an FPGA when the FPGA needs to
        read or write data to the processors memory.

        Parameters
        ----------
        None

        Returns
        -------
        int
            A 32-bit address that can be passed to an FPGA
        """
        return self.frame.get_phy_address()
        #return self.xlnk.cma_get_phy_addr(self.frame)

    def set_bytearray(self, byte_array):
        """Sets the raw bytes of the buffer

        It is up to the user to

        Parameters
        ----------

        Returns
        -------
        """
        self.frame.frame_raw(byte_array)
        #ba = self.get_bytearray()
        #ba[:] = byte_array

    def get_bytearray(self):
        """

        Parameters
        ----------

        Returns
        -------
        """

        return self.frame.frame_raw()
        #return self.xlnk.cma_get_buffer(self.frame, self.size)

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
        if self.frame is not None:
            del self.frame

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
            width = self.frame.width
        if height is None:
            height = self.frame.height
        np_frame = (np.frombuffer(self.get_bytearray(), dtype=np.uint8)). \
                      reshape(self.frame.height, self.frame.width, 3)\
                        [:height, :width, :]
        image = Image.fromarray(np_frame)
        image.save(path, 'JPEG')


    @property
    def width(self):
        return self.frame.width
        #return self.__width

    @property
    def height(self):
        return self.frame.height
        #return self.__height

    @property
    def color_depth(self):
        return self.frame.color_depth
        #return self.__color_depth

    @property
    def size(self):
        return self.frame.size
        #return self.width * self.height * self.color_depth

