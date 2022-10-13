#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import sys
import select
import termios
from time import sleep
import pytest
from pynq import Overlay
from pynq.overlays.base import BaseOverlay
from pynq.tests.util import user_answer_yes




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


