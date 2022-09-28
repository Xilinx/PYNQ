#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pytest
from pynq import Overlay
from pynq.overlays.base import BaseOverlay
from pynq.tests.util import user_answer_yes




try:
    ol = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest onboard buttons?")
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need base overlay and onboard buttons")
def test_btn_read():
    """Test for the Button class and its wrapper functions.

    Read button index 0 ~ 3, requesting user confirmation.

    """
    base = BaseOverlay("base.bit")
    print("")
    for index in range(4):
        assert base.buttons[index].read() == 0, \
            "Button {} reads wrong values.".format(index)
    for index in range(4):
        input("Hit enter while pressing Button {0} (BTN{0})...".format(index))
        assert base.buttons[index].read() == 1, \
            "Button {} reads wrong values.".format(index)


