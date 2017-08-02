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


import sys
import select
import termios
from time import sleep
import pytest
from pynq import Overlay
from pynq.overlays.base import BaseOverlay
from pynq.tests.util import user_answer_yes


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2015, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    ol = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest onboard RGB LEDs?")
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need base overlay and onboard RGB LEDs")
def test_rgbleds_index():
    """Test for the RGBLED class and its wrapper functions.

    Test whether the corresponding RGBLED objects exist.

    """
    base = BaseOverlay("base.bit")
    rgbleds = base.rgbleds
    rgbled_valid_index = [4, 5]

    for index, rgbled in enumerate(rgbleds):
        if index not in rgbled_valid_index:
            assert rgbled is None
        else:
            assert rgbled is not None


@pytest.mark.skipif(not flag, reason="need base overlay and onboard RGB LEDs")
def test_rgbleds_write():
    """Test for the RGBLED class and its wrapper functions.

    Control the two RGBLED objects, requesting user confirmation.

    """
    base = BaseOverlay("base.bit")
    rgbleds = base.rgbleds[4:6]

    for rgbled in rgbleds:
        rgbled.off()
        assert rgbled.read() == 0, 'Wrong state for RGBLED.'

    print("\nShowing 7 colors of RGBLED. Press enter to stop...", end="")
    color = 0
    while True:
        color = (color + 1) % 8
        for rgbled in rgbleds:
            rgbled.write(color)
            assert rgbled.read() == color, 'Wrong state for RGBLED.'
        sleep(0.5)
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
            break

    for rgbled in rgbleds:
        rgbled.off()
        assert rgbled.read() == 0, 'Wrong state for RGBLED.'

    assert user_answer_yes("RGBLEDs showing 7 colors during the test?")
