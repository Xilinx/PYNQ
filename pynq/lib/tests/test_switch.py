#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


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
flag1 = user_answer_yes("\nTest onboard switches?")
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need base overlay and onboard switches")
def test_switch_read():
    """Test for the Switch class and its wrapper functions.

    Read the 2 Switch objects, requesting user confirmation. A time delay
    is added when reading the values from the switches. This is to compensate
    the delay for asyncio read.

    """
    base = BaseOverlay("base.bit")
    print("\nSet the 2 switches (SW0 ~ SW1) off (lower position).") 
    input("Then hit enter...")
    switches = base.switches
    for index, switch in enumerate(switches):
        assert switch.read() == 0, \
            "Switch {} reads wrong values.".format(index)
    input("Now switch them on (upper position) and hit enter...")
    for index, switch in enumerate(switches):
        assert switch.read() == 1, \
            "Switch {} reads wrong values.".format(index)


