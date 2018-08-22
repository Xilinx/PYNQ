#   Copyright (c) 2018, Xilinx, Inc.
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

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"


class VideoMode:
    """Class for holding the information about a video mode

    Attributes
    ----------
    height : int
        Height of the video frame in lines
    width : int
        Width of the video frame in pixels
    stride : int
        Width of a line in the video frame in bytes
    bits_per_pixel : int
        Bits per pixel
    bytes_per_Pixel : int
        Bytes required to represent each pixel
    shape : tuple of int
        Numpy-style tuple describing the video frame

    """

    def __init__(self, width, height, bits_per_pixel, fps=60, stride=None):
        self.width = width
        self.height = height
        self.bits_per_pixel = bits_per_pixel
        self.bytes_per_pixel = ((bits_per_pixel - 1) // 8) + 1
        self.fps = fps
        if stride:
            self.stride = stride
        else:
            self.stride = width * self.bytes_per_pixel
        if self.bytes_per_pixel == 1:
            self.shape = (self.height, self.width)
        else:
            self.shape = (self.height, self.width, self.bytes_per_pixel)

    def __repr__(self):
        return ("VideoMode: width={} height={} bpp={}"
                .format(self.width, self.height, self.bits_per_pixel))


class PixelFormat:
    """Wrapper for all of the information about a video format

    Attributes
    ----------
    bits_per_pixel : int
        Number of bits for each pixel
    in_color : list of float
        Coefficients from BGR stream to pixel format
    out_color : list of float
        Coefficient from pixel format to BGR stream

    """

    def __init__(self, bits_per_pixel, in_color, out_color, fourcc=None):
        self.bits_per_pixel = bits_per_pixel
        self.in_color = in_color
        self.out_color = out_color
        self.fourcc = fourcc


COLOR_IN_BGR = [1, 0, 0,
                0, 1, 0,
                0, 0, 1,
                0, 0, 0]

COLOR_OUT_BGR = [1, 0, 0,
                 0, 1, 0,
                 0, 0, 1,
                 0, 0, 0]

COLOR_IN_RGB = [0, 0, 1,
                0, 1, 0,
                1, 0, 0,
                0, 0, 0]

COLOR_OUT_RGB = [0, 0, 1,
                 0, 1, 0,
                 1, 0, 0,
                 0, 0, 0]

COLOR_IN_YCBCR = [0.114, 0.587, 0.299,
                  0.5, -0.331264, -0.168736,
                  -0.081312, -0.41866, 0.5,
                  0, 0.5, 0.5]

COLOR_OUT_YCBCR = [1, 1.772, 0,
                   1, -0.3344136, -0.714136,
                   1, 0, 1.402,
                   -0.886, 0.529136, -0.701]

COLOR_OUT_GRAY = [1, 0, 0,
                  1, 0, 0,
                  1, 0, 0,
                  0, 0, 0]


PIXEL_RGB = PixelFormat(24, COLOR_IN_RGB, COLOR_OUT_RGB, "RG24")
PIXEL_RGBA = PixelFormat(32, COLOR_IN_RGB, COLOR_OUT_RGB, "RA24")
PIXEL_BGR = PixelFormat(24, COLOR_IN_BGR, COLOR_OUT_BGR, "BG24")
PIXEL_YCBCR = PixelFormat(24, COLOR_IN_YCBCR, COLOR_OUT_YCBCR, "YU24")
PIXEL_GRAY = PixelFormat(8, COLOR_IN_YCBCR, COLOR_OUT_GRAY)
