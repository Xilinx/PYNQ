#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import os

import pytest
from pynq import Overlay
from pynq.overlays.base import BaseOverlay
from pynq.tests.util import user_answer_yes



try:
    ol = Overlay("base.bit", download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nAUDIO OUT connected?")
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need base overlay and audio attached")
def test_audio_out():
    """Test whether audio out works properly.

    Test whether sound can be heard from the audio out jack. Record a 5-second
    sample and play it back.

    """
    base = BaseOverlay("base.bit")
    audio_t = base.audio

    print("\nSpeaking into the MIC for 5 seconds...")
    audio_t.record(5)
    input("Hit enter to play back...")
    audio_t.play()
    assert user_answer_yes("Heard playback on AUDIO OUT?")

    del audio_t


@pytest.mark.skipif(not flag, reason="need base overlay and audio attached")
def test_audio_playback():
    """Test the functionality of handling pdm files.

    Test whether the `*.pdm` file can be handled properly.

    There are 2 steps in this test:

    1. Load and play a pre-stored pdm file.

    2. Record a pdm file and play it back.

    """
    base = BaseOverlay("base.bit")
    audio_t = base.audio
    welcome_audio_path = "/home/xilinx/pynq/lib/tests/pynq_welcome.pdm"
    record_audio_path = "/home/xilinx/pynq/lib/tests/recorded.pdm"

    print("\nPlaying an audio file...")
    audio_t.load(welcome_audio_path)
    audio_t.play()
    assert user_answer_yes("Heard welcome message?")

    print("Speaking into the MIC for 5 seconds...")
    audio_t.record(5)
    audio_t.save(record_audio_path)
    input("Audio file saved. Hit enter to play back...")
    audio_t.load(record_audio_path)
    audio_t.play()
    assert user_answer_yes("Heard recorded sound?")

    os.remove(record_audio_path)
    del audio_t


