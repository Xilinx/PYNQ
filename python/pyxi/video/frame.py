
__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from itertools import chain
from PIL import Image
from . import _video
from . import _constants


class Frame(object):
    """Just a wrapper to the AV bytearray frame buffer that exposes 
    handy getter and setter.

    Parameters
    ----------
    frame  : bytearray
             The AV frame
    width : int
            The width of the frame
    height : int
             The height of the frame

    Attributes
    ----------
    frame  : bytearray
             From parameter :frame:
    width : int
            From parameter :width:
    height : int
             From parameter :height:
    """

    def __init__(self, width, height, frame=None):
        if frame is not None:
            self._framebuffer = None
            self.frame = frame
        else:
            # framebuffer with just 1 frame
            self._framebuffer = _video._frame(1)
            self.frame = self._framebuffer(0)  # empty frame
        self.width = width
        self.height = height

    def __getitem__(self, index):
        """Access the frame in the following way: 
        `frame[x, y]` to get the tuple (r,g,b) 
        or 
        `frame[x, y][rgb]` to access a specific color.

        Examples
        --------        
        Get the three component of pixel (48,32) as a tuple
        The object is called `frame`
        
        >>> frame[48,32]
        (128,64,12)


        Access the green component of pixel (48,32)

        >>> frame[48,32][1]
        64
        """
        x, y = index
        if 0 <= y < self.height and 0 <= x < self.width:
            offset = 3 * (y * _constants.MAX_FRAME_WIDTH + x)
            # To return a tuple (r,g,b), we need to take into account that
            # the original frame stores pixels as GBR
            # so @0 there is Green, @1 there is Blue and @2 there is Red
            return self.frame[offset + 2], self.frame[offset], \
                self.frame[offset + 1]
        else:
            raise ValueError("Index is out of range.")

    def __setitem__(self, index, value):
        """Access the frame in the following way: 
        `frame[x, y] = (r,g,b)` to set the entire RGB tuple
        or 
        `frame[x, y][rgb] = new_color_value` to set a specific color.

        Examples
        --------
        Set pixel (0,0)
        The object is called `frame`
        
        >>> frame[0,0] = (255,255,255)

        
        Set the blue component of pixel (0,0) to be 128
        
        >>> frame[0,0][2] = 128               
        """
        x, y = index
        if 0 <= y < self.height and 0 <= x < self.width:
            offset = 3 * (y * _constants.MAX_FRAME_WIDTH + x)
            self.frame[offset + 2] = value[0]
            self.frame[offset] = value[1]
            self.frame[offset + 1] = value[2]
        else:
            raise ValueError("Index is out of range.")

    def __del__(self):
        if self._framebuffer is not None:
            del self._framebuffer  # free memory

    def save_as_jpeg(self, path):
        """Save the frame as a JPEG image.

        Parameters
        ----------
        path : str
               where the JPEG will be saved. The JPEG filename must be included
               in the path
        """
        rgb = bytearray()
        for i in range(0, self.height):
            row = self.frame[i * _constants.MAX_FRAME_WIDTH * 3 :/
                             (i * _constants.MAX_FRAME_WIDTH + self.width) * 3]
            rgb.extend(bytearray(
                         chain.from_iterable(
                           (row[j + 2], row[j], row[j + 1])/
                           for j in range(0, len(row) - 1, 3))))

        image = Image.frombytes('RGB', (self.width, self.height), bytes(rgb))
        image.save(path, 'JPEG')

    @staticmethod
    def save_raw_as_jpeg(path, frame_raw, height, width):
        """Static method to save an AV raw frame - i.e. a bytearray - as a 
        JPEG image.

        Parameters
        ----------
        path : str
               where the JPEG will be saved. The JPEG filename must be included
               in the path
        frame_raw : bytearray
                    The AV frame
        width : int
                The width of the frame
        height : int
                 The height of the frame        
        """
        rgb = bytearray()
        for i in range(0, height):
            row = frame_raw[i * _constants.MAX_FRAME_WIDTH * 3 :/
                            (i * _constants.MAX_FRAME_WIDTH + width) * 3]
            rgb.extend(bytearray(
                         chain.from_iterable(
                           (row[j + 2], row[j], row[j + 1])/
                           for j in range(0, len(row) - 1, 3))))

        image = Image.frombytes('RGB', (width, height), bytes(rgb))
        image.save(path, 'JPEG')
