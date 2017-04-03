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

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"

import os
import re
import csv
import json
import numpy as np
import copy
from .intf_const import ARDUINO
from .intf_const import MAILBOX_OFFSET
from .intf_const import MAILBOX_PY2DIF_CMD_OFFSET
from .intf_const import INPUT_SAMPLE_SIZE
from .intf_const import OUTPUT_SAMPLE_SIZE
from .intf_const import INPUT_PIN_MAP
from .intf_const import OUTPUT_PIN_MAP
from .intf_const import TRI_STATE_MAP
from .intf_const import MAILBOX_PY2DIF_CMD_OFFSET
from .intf import request_intf
from .waveform import Waveform

ARDUINO_PG_PROGRAM = "arduino_intf.bin"


def _bitstring_to_wave(bitstring):
    """Function to convert a pattern consisting of `0`, `1` into a sequence
    of `l`, `h`, and dots.

    For example, if the bit string is "010011000111", then the result will be
    "lhl.h.l..h..".

    Returns
    -------
    str
        New wave tokens with valid tokens and dots.

    """
    substitution_map = {'0': 'l', '1': 'h', '.': '.'}
    def insert_dots(match):
        return substitution_map[match.group()[0]] + \
               '.' * (len(match.group()) - 1)

    bit_regex = re.compile(r'[0][0]*|[1][1]*')
    return re.sub(bit_regex, insert_dots, bitstring)


class PatternAnalyzer:
    """Class for the Pattern Analyzer.

    This class can capture digital IO patterns / stimulus on all the pins.
    When a pin is specified as input, the response can be captured.

    Attributes
    ----------
    if_id : int
        The interface ID (ARDUINO).

    """

    def __init__(self, if_id):
        """Return a new Arduino_PG object.

        Parameters
        ----------
        if_id : int
            The interface ID (ARDUINO).
        dst_samples: numpy.ndarray
            The numpy array storing the response, each sample being 64 bits.

        """
        if os.geteuid() != 0:
            raise EnvironmentError('Root permissions required.')
        if if_id not in [ARDUINO]:
            raise ValueError("No such INTF for Arduino interface.")

        self.if_id = if_id

    def analyze(self, samples):
        """Analyze the captured pattern.

        This function will process the captured pattern and put the pattern
        into a Wavedrom compatible format.

        Each bit of the 20-bit patterns, from LSB to MSB, corresponds to:
        D0, D1, ..., D19, A0, A1, ..., A5, respectively.

        The data output is of format:

        [{'pin': 'D1', 'wave': '1...0.....'},
        {'pin': 'D2', 'wave': '0.1..01.01'}]

        Note the all the lanes should have the same number of samples.

        Parameters
        ----------
        samples : numpy.ndarray
            A numpy array consisting of all the samples.

        Returns
        -------
        list
            A list of dictionaries, each dictionary consisting the pin number,
            and the waveform pattern in string format.

        """
        num_samples = len(samples)
        temp_samples = np.zeros(num_samples, dtype='>i8')
        np.copyto(temp_samples, samples)
        temp_bytes = np.frombuffer(temp_samples, dtype=np.uint8)
        bit_array = np.unpackbits(temp_bytes)
        temp_lanes = bit_array.reshape(num_samples,
                                       INPUT_SAMPLE_SIZE).T[::-1]
        wavelanes = list()
        for pin_label in INPUT_PIN_MAP:
            output_lane = temp_lanes[OUTPUT_PIN_MAP[pin_label]]
            input_lane = temp_lanes[INPUT_PIN_MAP[pin_label]]
            tri_lane = temp_lanes[TRI_STATE_MAP[pin_label]]
            cond_list = [tri_lane == 0, tri_lane == 1]
            choice_list = [output_lane, input_lane]
            temp_lane = np.select(cond_list, choice_list)
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = _bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        return wavelanes
