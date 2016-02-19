
__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


import pytest
from time import sleep
from pyxi.video import HDMI
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nHDMI port connected to a video source?")

@pytest.mark.run(order=37)  
@pytest.mark.skipif(not flag, reason="need HDMI connected")  
def test_hdmi():
    """TestCase for the HDMI class with direction set as input."""
    hdmi = HDMI('in')
    print("\nLoading ...")
    assert hdmi.direction is 'in', 'HDMI direction is wrong'
    sleep(10)

    frame_raw = hdmi.frame_raw()
    assert len(frame_raw)==1920*1080*3, 'wrong frame size'

    index = hdmi.frame_index()
    hdmi.frame_index(index + 1)
    assert not hdmi.frame_index()==index, 'frame index is not changed'        

