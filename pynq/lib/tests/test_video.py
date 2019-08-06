#   Copyright (c) 2017, Xilinx, Inc.
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


from time import sleep
import numpy as np
import pytest
from pynq import Overlay
from pynq.lib.video import *
from pynq.tests.util import user_answer_yes


__author__ = "Peter Ogden"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


flag_hdmi = user_answer_yes(
    "\nAre the HDMI input and output connected together?")


def load_test_image_rgb(frame):
    shape = frame.shape
    framesize = shape[0:2]
    framesize_t = shape[1:-1:-1]
    rowval = np.arange(shape[0], dtype=np.uint8)
    colval = np.arange(shape[1], dtype=np.uint8)
    frame[:, :, 0] = np.broadcast_to(rowval[:, np.newaxis], framesize)
    frame[:, :, 1] = np.broadcast_to(colval[np.newaxis, :], framesize)
    np.outer(rowval, colval, out=frame[:, :, 2])


@pytest.fixture(scope="function")
def video():
    base = Overlay('base.bit', download=True)
    yield base.video
    base.video.hdmi_in.close()
    base.video.hdmi_out.close()


@pytest.mark.skipif(not flag_hdmi, reason="need HDMI loopback")
def test_hdmi_pipeline(video):
    """Test for the HDMI pipe.

    Outputs a known image on the HDMI out and reads a single frame from the
    HDMI input and checks that it matches.

    """
    hdmi_in = video.hdmi_in
    hdmi_out = video.hdmi_out
    mode = VideoMode(1280, 720, 24)
    ref_frame = np.ndarray(shape=mode.shape, dtype=np.uint8)
    load_test_image_rgb(ref_frame)
    with hdmi_out.configure(mode):
        hdmi_out.start()
        out_frame = hdmi_out.newframe()
        out_frame[:] = ref_frame
        hdmi_out.writeframe(out_frame)
        hdmi_in.configure()
        with hdmi_in.start():
            in_frame = hdmi_in.readframe()
            assert np.array_equal(in_frame, ref_frame)
            in_frame.freebuffer()


@pytest.mark.skipif(not flag_hdmi, reason="need HDMI loopback")
def test_hdmi_latency(video):
    """Test the latency of the video pipeline

    Changes the image on the input and times how it takes for the new
    image to appear at the input. Only a small part of the image is checked
    against the reference in each loop

    """
    hdmi_in = video.hdmi_in
    hdmi_out = video.hdmi_out
    mode = VideoMode(1280, 720, 24)
    ref_frame = np.ndarray(shape=mode.shape, dtype=np.uint8)
    load_test_image_rgb(ref_frame)
    with hdmi_out.configure(mode):
        hdmi_out.start()
        hdmi_in.configure()
        out_frame = hdmi_out.newframe()
        out_frame[:] = ref_frame
        with hdmi_in.start():
            # Dummy frame read to make sure everything is initialised
            in_frame = hdmi_in.readframe()
            hdmi_out.writeframe(out_frame)
            count = 0
            while in_frame[1, 1, 1] != ref_frame[1, 1, 1]:
                in_frame.freebuffer()
                in_frame = hdmi_in.readframe()
                count += 1
            assert np.array_equal(in_frame, ref_frame)
            assert count < 5
            in_frame.freebuffer()


def generate_colorspace(inchannel, outchannel):
    colorspace = [0.0] * 12
    colorspace[outchannel * 3 + inchannel] = 1.0
    return colorspace


@pytest.mark.skipif(not flag_hdmi, reason="need HDMI loopback")
def test_hdmi_8bit_output(video):
    """Test that the 8-bit mode of the video interface works correctly

    This test outputs 8-bits per pixel on the output and cycles through
    each channel using the color converter making sure the output is
    correct

    """
    hdmi_in = video.hdmi_in
    hdmi_out = video.hdmi_out
    out_mode = VideoMode(1280, 720, 8)
    in_mode = VideoMode(1280, 720, 24)
    ref_frame = np.ndarray(shape=in_mode.shape, dtype=np.uint8)
    load_test_image_rgb(ref_frame)
    with hdmi_out.configure(out_mode):
        hdmi_out.start()
        out_frame = hdmi_out.newframe()
        out_frame[:] = ref_frame[:, :, 0]
        hdmi_out.writeframe(out_frame)
        with hdmi_in.configure():
            for i in range(3):
                hdmi_out.colorspace = generate_colorspace(0, i)
                hdmi_in.start()
                with hdmi_in.readframe() as in_frame:
                    assert np.array_equal(
                        in_frame[:, :, i], ref_frame[:, :, 0])
                hdmi_in.stop()


@pytest.mark.skipif(not flag_hdmi, reason="need HDMI loopback")
def test_hdmi_8bit_input(video):
    """Test that the 8-bit mode of the video interface works correctly

    This test outputs 8-bits per pixel on the output and cycles through
    each channel using the color converter making sure the output is
    correct

    """
    hdmi_in = video.hdmi_in
    hdmi_out = video.hdmi_out
    out_mode = VideoMode(1280, 720, 24)
    in_mode = VideoMode(1280, 720, 8)
    ref_frame = np.ndarray(shape=out_mode.shape, dtype=np.uint8)
    load_test_image_rgb(ref_frame)
    with hdmi_out.configure(out_mode):
        hdmi_out.start()
        out_frame = hdmi_out.newframe()
        out_frame[:] = ref_frame[:]
        hdmi_out.writeframe(out_frame)
        with hdmi_in.configure(PIXEL_GRAY):
            for i in range(3):
                hdmi_in.colorspace = generate_colorspace(i, 0)
                hdmi_in.start()
                with hdmi_in.readframe() as in_frame:
                    assert np.array_equal(in_frame, ref_frame[:, :, i])
                hdmi_in.stop()


@pytest.mark.skipif(not flag_hdmi, reason="need HDMI loopback")
def test_hdmi_tie(video):
    hdmi_in = video.hdmi_in
    hdmi_out = video.hdmi_out
    mode = VideoMode(1280, 720, 24)
    with hdmi_out.configure(mode):
        hdmi_out.start()
        with hdmi_in.configure():
            hdmi_in.start()
            # Ensure the frame cache is populated
            for i in range(5):
                hdmi_in.readframe().freebuffer()
            frames = [hdmi_out.newframe() for _ in range(6)]
            for i in range(6):
                frames[i][:] = [i]
            for i in range(6):
                hdmi_out.writeframe(frames[i])
            hdmi_in.tie(hdmi_out)
            last_val = 6
            start_time = time.time()
            for i in range(60):
                in_frame = hdmi_in.readframe()
                this_val = in_frame[0, 0, 0]
                assert this_val == last_val + 1 or this_val < last_val,\
                    "Frame skipped"
                in_frame.freebuffer()
            end_time = time.time()
            assert end_time - start_time < 1.1, "Missed reads"


def test_colorspace_readwrite(video):
    colorspace = [-1.5, -1.25, -1,
                  0.5, 0, 0.125,
                  0.5, 1, 1.5,
                  0, 0, 0]

    video.hdmi_in.color_convert.colorspace = colorspace
    assert video.hdmi_in.color_convert.colorspace == colorspace

    video.hdmi_out.color_convert.colorspace = colorspace
    assert video.hdmi_out.color_convert.colorspace == colorspace
