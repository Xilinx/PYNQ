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
import ctypes
import copy
from .intf_const import ARDUINO
from .intf_const import PATTERN_FREQUENCY_MHZ
from .intf_const import INPUT_SAMPLE_SIZE
from .intf_const import INPUT_PIN_MAP
from .intf_const import OUTPUT_SAMPLE_SIZE
from .intf_const import OUTPUT_PIN_MAP
from .intf_const import CMD_GENERATE_PATTERN_SINGLE
from .intf import request_intf
from .waveform import Waveform
from .pattern_analyzer import PatternAnalyzer

ARDUINO_PG_PROGRAM = "arduino_intf.bin"

def _wave_to_bitstring(wave):
    """Function to convert a pattern consisting of `l`, `h`, and dot to a
    sequence of `0` and `1`.

    Parameters
    ----------
    wave : str
        The input string to convert.

    Returns
    -------
    list
        A list of elements, each element being 0 or 1.

    """
    substitution_map = {'l': '0', 'h': '1'}
    def delete_dots(match):
        return substitution_map[match.group()[0]] * len(match.group())

    wave_regex = re.compile(r'[l]\.*|[h]\.*')
    return re.sub(wave_regex, delete_dots, wave)

def _bitstring_to_int(bitstring):
    """Function to convert a bit string to integer list.

    For example, if the bit string is '0110', then the integer list will be
    [0,1,1,0].

    Parameters
    ----------
    bistring : str
        The input string to convert.

    Returns
    -------
    list
        A list of elements, each element being 0 or 1.

    """
    return [int(i,10) for i in list(bitstring)]

def _int_to_sample(bits):
    """Function to convert a bit list into a multi-bit sample.

    Example: [1, 1, 1, 0] will be converted to 7, since the LSB of the sample
    appears first in the sequence.

    Parameters
    ----------
    bits : list
        A list of bits, each element being 0 or 1.

    Returns
    -------
    int
        A numpy uint32 converted from the bit samples.

    """
    return np.uint32(int("".join(map(str, list(bits[::-1]))), 2))


class PatternGenerator:
    """Class for the Pattern Generator.

    This class can generate digital IO patterns / stimulus on output pins.
    Users can specify whether to use a pin as input or output.

    Attributes
    ----------
    if_id : int
        The interface ID (ARDUINO).
    intf : _INTF
        INTF instance used by Arduino_PG class.
    waveform : Waveform
        The Waveform object used for Wavedrom display.
    src_samples: numpy.ndarray
        The numpy array storing the stimuli, each sample being 32 bits.
    dst_samples: numpy.ndarray
        The numpy array storing the response, each sample being 64 bits.

    """

    def __init__(self, if_id, waveform_dict, stimulus_name='stimulus',
                 analysis_name='analysis', use_analyzer=True):
        """Return a new Arduino_PG object.

        Parameters
        ----------
        if_id : int
            The interface ID (ARDUINO).
        waveform_dict : dict
            Waveform dictionary in WaveJSON format.
        stimulus_name : str
            Name of the WaveLane group for the stimulus, defaulted to
            `stimulus`.
        analysis_name : str
            Name of the WaveLane group for the analysis, defaulted to
            `analysis`.
        use_analyzer : bool
            Indicate whether to use the analyzer to capture the trace as well.

        """
        if os.geteuid() != 0:
            raise EnvironmentError('Root permissions required.')
        if if_id not in [ARDUINO]:
            raise ValueError("No such INTF for Arduino interface.")

        self.if_id = if_id
        self.intf = request_intf(if_id, ARDUINO_PG_PROGRAM)
        self.src_samples = None
        self.dst_samples = None
        self.waveform = Waveform(waveform_dict, stimulus_name=stimulus_name,
                                 analysis_name=analysis_name)
        self.stimulus_name = stimulus_name
        self.analysis_name = analysis_name
        self.stimulus_group = self.waveform.stimulus_group
        self.analysis_group = self.waveform.analysis_group
        self.stimulus_names = self.waveform.stimulus_names
        self.stimulus_pins = self.waveform.stimulus_pins
        self.stimulus_waves = self.waveform.stimulus_waves
        self._wave_length_equal = self._is_wave_length_equal()
        self._longest_wave, self._max_wave_length = self._get_max_wave_length()

        if use_analyzer:
            self.analyzer = PatternAnalyzer(if_id)
        else:
            self.analyzer = None

    @property
    def max_wave_length(self):
        """Return the maximum wave length

        Will only be changed by internal method.

        """
        return self._max_wave_length

    @property
    def longest_wave(self):
        """Return the name of the longest wave.

        Will only be changed by internal method.

        """
        return self._longest_wave

    def _is_wave_length_equal(self):
        """Test if all the waves are of the same length.

        Test if all the waves have the same number of tokens / samples.

        Returns
        -------
        Bool
            True if all waves have same number of tokens.

        """
        for wave in self.stimulus_waves:
            if len(wave) != len(self.stimulus_waves[0]):
                return False
        return True

    def _get_max_wave_length(self):
        """Find longest wave (with most tokens).

        This function returns the name and the length of the longest wave.
        If all the waves have the same length, the returned name will be
        the first one in the waves list.

        Returns
        -------
        (str,int)
            Name and length of the longest wave.

        """
        if self._is_wave_length_equal():
            return self.stimulus_names[0],\
                   len(self.stimulus_waves[0])
        else:
            max_wave_length = 0
            name_of_longest_wave = ''
            for index,wave in enumerate(self.stimulus_waves):
                if len(wave) > max_wave_length:
                    max_wave_length = len(wave)
                    name_of_longest_wave = self.stimulus_names[index]
            return name_of_longest_wave, max_wave_length

    def _make_same_wave_length(self):
        """Set the all the waves to the same length.

        This method will pad the same tokens to the end of all the shorter
        waves. For example, if there are only 2 waves:
        'lhlhlh' (length of 6) and 'llhhllhh' (length of 8), then the shorter
        one will be converted to: 'lhlhlhhh' (repeating the last token two
        more times).

        Returns
        -------
        (str,int)
            Name and length of the longest wave.

        """
        for index, wave in enumerate(self.stimulus_waves):
            len_diff = self._max_wave_length - len(wave)
            if len_diff:
                self.stimulus_waves[index] = wave + wave[-1] * len_diff
                print(f"WaveLane {self.stimulus_names[index]} extended to "+
                      f"{self._max_wave_length} tokens to match "+
                      f"{self._longest_wave}, " +
                      f"the longest WaveLane in the group.")

    def generate(self, frequency_mhz=PATTERN_FREQUENCY_MHZ):
        """Configure the PG with a single bit pattern.

        Generates a bit pattern for a single shot operation at specified IO 
        pins with the specified number of samples.
        
        Each bit of the 20-bit patterns, from LSB to MSB, corresponds to:
        D0, D1, ..., D19, A0, A1, ..., A5, respectively.

        Note the all the lanes should have the same number of samples. And the
        token inside wave are already converted into bit string.

        Users can ignore the returned data in case only the pattern
        generator is required.
        
        Parameters
        ----------
        frequency_mhz: float
            The frequency of the captured samples, in MHz.

        Returns
        -------
        (numpy.ndarray,numpy.ndarray)
            The generated samples, and the captured samples.

        """
        self._make_same_wave_length()
        self.intf.clk.fclk1_mhz = frequency_mhz
        direction_mask = 0xFFFFF
        num_samples = self._max_wave_length
        temp_lanes = np.zeros((OUTPUT_SAMPLE_SIZE, num_samples),
                              dtype=np.uint8)
        data = self.stimulus_waves[:]
        for index, wave in enumerate(data):
            pin_number = OUTPUT_PIN_MAP[self.stimulus_pins[index]]
            direction_mask &= (~(1 << pin_number))
            temp_lanes[pin_number] = data[index] = _bitstring_to_int(
                                                    _wave_to_bitstring(wave))
        temp_samples = temp_lanes.T.copy()
        self.src_samples = np.apply_along_axis(_int_to_sample,1,temp_samples)

        # Allocate the source and destination buffers
        src_addr = self.intf.allocate_buffer('src_buf',num_samples,
                                             data_type="unsigned int")
        dst_addr = self.intf.allocate_buffer('dst_buf',num_samples,
                                             data_type="unsigned long long")

        # Write samples into the source buffer
        for index, data in enumerate(self.src_samples):
            self.intf.buffers['src_buf'][index] = data

        # Wait for the interface processor to return control
        self.intf.write_control([direction_mask,src_addr,num_samples,dst_addr])
        self.intf.write_command(CMD_GENERATE_PATTERN_SINGLE)

        # Construct the numpy array from the destination buffer
        if self.analyzer:
            self.dst_samples = self.intf.ndarray_from_buffer(
                                    'dst_buf',num_samples*8,dtype=np.uint64)
            self.analysis_group = self.analyzer.analyze(self.dst_samples)
            self.waveform.update(self.analysis_name, self.analysis_group)

        # Free the 2 buffers
        self.intf.free_buffer('src_buf')
        self.intf.free_buffer('dst_buf')