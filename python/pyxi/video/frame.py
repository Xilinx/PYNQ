
__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


class Frame(object):
    """Just a wrapper to a bytearray frame buffer that exposes handy getter and
    setter.

    Arguments
    ----------
    frame  (bytearray)  : The frame as a bytearray
    width  (int)        : The width of the frame
    height (int)        : The height of the frame

    Attributes
    ----------
    *same as Arguments*
    """
    def __init__(self, width, height, frame=None):
        if frame is not None:
            self.frame = frame
        else:
            self.frame = bytearray(1920*1080*3) # empty frame
        self.width = width
        self.height = height

    def __getitem__(self, index):
        """Access the frame in the following way: 
        'frame[x, y]' to get the tuple (r,g,b) 
        or 
        'frame[x, y][rgb]' to access a specific color.
        """
        x, y = index
        if 0 <= y < self.height and 0 <= x < self.width:
            offset = 3 * (y * 1920 + x)
            # To return a tuple (r,g,b), we need to take into account that 
            # the original frame stores pixels as GRB
            # so @0 there is Green, @1 there is Red and @2 there is blue
            return self.frame[offset + 2], self.frame[offset], \
                   self.frame[offset + 1]
        else:
            raise ValueError("Index is out of range.")

    def __setitem__(self, index, value):
        """Access the frame in the following way: 
        'frame[x, y] = (r,g,b)'' to set the entire rgb tuple
        or 
        'frame[x, y][rgb] = new_color_value' to set a specific color.
        """
        x, y = index
        if 0 <= y < self.height and 0 <= x < self.width:
            offset = 3 * (y * 1920 + x)
            self.frame[offset + 2] = value[0]
            self.frame[offset] = value[1]
            self.frame[offset + 1] = value[2]
        else:
            raise ValueError("Index is out of range.")
