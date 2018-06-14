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

from pynq import DefaultIP
from .common import *


class ColorConverter(DefaultIP):
    """Driver for the color space converter

    The colorspace convert implements a 3x4 matrix for performing arbitrary
    linear color conversions. Each coefficient is represented as a 10 bit
    signed fixed point number with 2 integer bits. The result of the
    computation can visualised as a table

    #      in1 in2 in3 1
    # out1  c1  c2  c3 c10
    # out2  c4  c5  c6 c11
    # out3  c7  c8  c9 c12

    The color can be changed mid-stream.

    Attributes
    ----------
    colorspace : list of float
        The coefficients of the colorspace conversion

    """

    def __init__(self, description):
        """Construct an instance of the driver

        Attributes
        ----------
        description : dict
            IP dict entry for the IP core

        """
        super().__init__(description)

    bindto = ['xilinx.com:hls:color_convert:1.0',
              'xilinx.com:hls:color_convert_2:1.0']

    @staticmethod
    def _signextend(value):
        """Sign extend a 10-bit number

        Derived from https://stackoverflow.com/questions/32030412/
                             twos-complement-sign-extension-python

        """
        return (value & 0x1FF) - (value & 0x200)

    @property
    def colorspace(self):
        """The colorspace to convert. See the class description for
        details of the coefficients. The coefficients are a list of
        floats of length 12

        """
        return [ColorConverter._signextend(self.read(0x10 + 8 * i)) / 256
                for i in range(12)]

    @colorspace.setter
    def colorspace(self, color):
        if len(color) != 12:
            raise ValueError("Wrong number of elements in color specification")
        for i, c in enumerate(color):
            self.write(0x10 + 8 * i, int(c * 256))


class PixelPacker(DefaultIP):
    """Driver for the pixel format convert

    Changes the number of bits per pixel in the video stream. The stream
    should be paused prior to the width being changed. This can be targeted
    at either a pixel_pack or a pixel_unpack IP core.For a packer the input
    is always 24 bits per pixel while for an unpacker the output 24 bits per
    pixel.

    """

    def __init__(self, description):
        """Construct an instance of the driver

        Attributes
        ----------
        description : dict
            IP dict entry for the IP core

        """
        super().__init__(description)
        self._bpp = 24
        self.write(0x10, 0)
        self._resample = False

    bindto = ['xilinx.com:hls:pixel_pack:1.0',
              'xilinx.com:hls:pixel_unpack:1.0',
              'xilinx.com:hls:pixel_pack_2:1.0',
              'xilinx.com:hls:pixel_unpack_2:1.0']

    @property
    def bits_per_pixel(self):
        """Number of bits per pixel in the stream

        Valid values are 8, 24 and 32. The following table describes the
        operation for packing and unpacking for each width

        Mode     Pack                          Unpack
        8  bpp   Keep only the first channel   Pad other channels with 0
        16 bpp   Dependent on resample         Dependent on resample
        24 bpp   No change                     No change
        32 bpp   Pad channel 4 with 0          Discard channel 4

        """
        mode = self.read(0x10)
        if mode == 0:
            return 24
        elif mode == 1:
            return 32
        elif mode == 2:
            return 8
        elif mode <= 4:
            return 16

    @bits_per_pixel.setter
    def bits_per_pixel(self, value):
        if value == 24:
            mode = 0
        elif value == 32:
            mode = 1
        elif value == 8:
            mode = 2
        elif value == 16:
            if self._resample:
                mode = 4
            else:
                mode = 3
        else:
            raise ValueError("Bits per pixel must be 8, 16, 24 or 32")
        self._bpp = value
        self.write(0x10, mode)

    @property
    def resample(self):
        """Perform chroma resampling in 16 bpp mode

        Boolean property that only affects 16 bpp mode. If True then
        the two chroma channels are multiplexed on to the second output
        pixel, otherwise only the first and second channels are transferred
        and the third is discarded
        """
        return self._resample

    @resample.setter
    def resample(self, value):
        self._resample = value
        # Make sure the mode is updated
        if self.bits_per_pixel == 16:
            self.bits_per_pixel = 16
