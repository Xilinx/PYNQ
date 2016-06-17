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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import sys
import select
import termios
import pytest
from pynq import Overlay
from pynq.drivers import LineIn
from pynq.drivers import Headphone
from pynq.test.util import user_answer_yes

flag = user_answer_yes("\nBoth LineIn and Headphone (HPH) jacks connected?")

@pytest.mark.run(order=30)
@pytest.mark.skipif(not flag, reason="need both LineIn and HPH attached")
def test_audio_loop():
    """Test whether LineIn and Headphone work properly.
    
    This test will use the __call__() methods of the two classes, and ask for
    the confirmation from the users.
    
    """
    headphone = Headphone()
    linein = LineIn()
    print("\nMake sure LineIn is receiveing audio. Hit enter to stop...", \
            end="")
    while True:
        headphone(linein())
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
            break
    assert user_answer_yes("Heard audio on the headphone (HPH) port?"),\
        'Audio loop is not working.'

@pytest.mark.run(order=31)
@pytest.mark.skipif(not flag, reason="need both LineIn and HPH attached")
def test_audio_mute():
    """Test is_muted() and toggle_mute() methods.
    
    The test will mute and unmute the volume, then ask for the confirmation
    from the users.
    
    """ 
    headphone = Headphone()
    linein = LineIn()
    print("\nMake sure LineIn is receiveing audio. Hit enter to mute...", \
            end="")
    while True:
        headphone(linein())
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
            break
    is_muted = headphone.controller.muted
    headphone.controller.toggle_mute()
    assert not is_muted is headphone.controller.muted, \
        'Cannot mute audio.'
    print("Audio is muted. Wait for a few seconds...")
    for i in range(100000):
        # Users should not be able to hear sound in this loop
        headphone(linein())
    assert user_answer_yes("Audio on the headphone (HPH) port muted?"),\
        'Cannot mute audio.'
    
