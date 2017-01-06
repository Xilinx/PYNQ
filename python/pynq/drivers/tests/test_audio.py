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
__email__       = "pynq_support@xilinx.com"


import os
import sys
import select
import termios
import pytest
from pynq import PL
from pynq.drivers import Audio 
from pynq.tests.util import user_answer_yes

flag = user_answer_yes("\nAUDIO OUT connected?")

@pytest.mark.run(order=31)
@pytest.mark.skipif(not flag, reason="need audio out attached")
def test_audio_out():
    """Test whether audio out works properly.
    
    Test whether sound can be heard from the audio out jack. Record a 5-second 
    sample and play it back.
    
    """
    audio_t = Audio()
    
    assert audio_t.mmio.base_addr==PL.ip_dict['SEG_d_axi_pdm_1_S_AXI_reg'][0],\
        'Wrong base address for audio IP.'
    assert audio_t.mmio.length==PL.ip_dict['SEG_d_axi_pdm_1_S_AXI_reg'][1],\
        'Wrong address range for audio IP.'
    
    print("\nSpeaking into the MIC for 5 seconds...")
    audio_t.record(5)
    input("Hit enter to play back...")
    audio_t.play()
    assert user_answer_yes("Heard playback on AUDIO OUT?")
    
    del audio_t

@pytest.mark.run(order=32)
@pytest.mark.skipif(not flag, reason="need audio out attached")
def test_audio_playback():
    """Test the functionality of handling pdm files.
    
    Test whether the `*.pdm` file can be handled properly.
    
    There are 2 steps in this test:
    
    1. Load and play a pre-stored pdm file.
    
    2. Record a pdm file and play it back.
    
    """
    audio_t = Audio()
    
    print("\nPlaying an audio file...")
    audio_t.load("/home/xilinx/pynq/drivers/tests/pynq_welcome.pdm")
    audio_t.play()
    assert user_answer_yes("Heard welcome message?")
    
    print("Speaking into the MIC for 5 seconds...")
    audio_t.record(5)
    audio_t.save("/home/xilinx/pynq/drivers/tests/recorded.pdm")
    input("Audio file saved. Hit enter to play back...")
    audio_t.load("/home/xilinx/pynq/drivers/tests/recorded.pdm")
    audio_t.play()
    assert user_answer_yes("Heard recorded sound?")
    
    os.remove("/home/xilinx/pynq/drivers/tests/recorded.pdm")
    del audio_t
    