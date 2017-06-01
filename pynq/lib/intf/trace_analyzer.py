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

import os
import re
import numpy as np
from .intf_const import INTF_MICROBLAZE_BIN, CMD_CONFIG_TRACE, \
    BYTE_WIDTH_TO_CTYPE, CMD_ARM_TRACE, BYTE_WIDTH_TO_NPTYPE
from .intf import request_intf, _INTF

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


def bitstring_to_wave(bitstring):
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


class TraceAnalyzer:
    """Class for the Trace Analyzer.

    This class can capture digital IO patterns / stimulus on all the pins.
    When a pin is specified as input, the response can be captured.

    Attributes
    ----------
    intf : _INTF
        INTF instance used by Arduino_PG class.
    trace_spec : dict
        The trace spec of similar format as PYNQZ1_DIO_SPECIFICATION.
    num_samples : int
        The number of samples to be analyzed.
    samples : numpy.ndarray
        The raw data samples expressed in numpy array.

    """
    def __init__(self, intf_microblaze, num_samples=4096, trace_spec=None):
        """Return a new Arduino_PG object.

        Parameters
        ----------
        intf_microblaze : _INTF/int
            The interface object or interface ID.
        num_samples : int
            The number of samples to be analyzed.
        trace_spec : dict
            The trace spec of similar format as PYNQZ1_DIO_SPECIFICATION.

        """

        if isinstance(intf_microblaze, _INTF):
            self.intf = intf_microblaze
        elif isinstance(intf_microblaze, int):
            self.intf = request_intf(intf_microblaze, INTF_MICROBLAZE_BIN)
        else:
            raise TypeError(
                "intf_microblaze has to be a intf._INTF or int type.")

        self.trace_spec = trace_spec
        self.num_samples = num_samples
        self.samples = None

    def config(self):
        """Configure the trace analyzer.
        
        This method prepares the trace analyzer by sending configuration 
        parameters to the intf Microblaze.

        """
        # Get width in bytes and send to allocator held with intf Microblaze
        trace_bit_width = self.trace_spec['monitor_width']
        trace_byte_width = round(trace_bit_width / 8)

        if 'trace_buf' in self.intf.buffers:
            buffer_phy_addr = self.intf.get_phy_addr_from_buffer('trace_buf')
        else:
            buffer_phy_addr = self.intf.allocate_buffer('trace_buf',
                            self.num_samples,
                            data_type=BYTE_WIDTH_TO_CTYPE[trace_byte_width])

        self.intf.write_control([buffer_phy_addr, self.num_samples, 0, 0])
        self.intf.write_command(CMD_CONFIG_TRACE)

    def arm(self):
        """Arm the analyzer.
        
        This method prepares the trace analyzer before analyzing samples.

        """
        self.intf.write_command(CMD_ARM_TRACE)

    def is_armed(self):
        """ Check if this builder's hardware is armed """
        return self.intf.armed_builders[CMD_ARM_CFG]

    def run(self):
        """Start the pattern analysis.
        
        This method will send the start command to the intf Microblaze.

        """
        self.intf.run()

    def stop(self):
        """Stop the pattern analysis.
        
        This method will send the stop command to the intf Microblaze.
        
        """
        self.intf.stop()

    def reset(self):
        """Free the trace buffer after use.

        Most of the time, users want to keep the trace buffer alive in order
        to continuously dump data into it; this method is a standalone method
        to free that buffer after use. 
        
        This method has to be called separately (in rare cases).

        """
        self.intf.free_buffer('trace_buf')

    def analyze(self, trace_spec=None):
        """Analyze the captured pattern.

        This function will process the captured pattern and put the pattern
        into a Wavedrom compatible format.

        Each bit of the 20-bit patterns, from LSB to MSB, corresponds to:
        D0, D1, ..., D18 (A4), D19 (A5), respectively.

        The data output is of format:

        [{'name': '', 'pin': 'D1', 'wave': '1...0.....'},
         {'name': '', 'pin': 'D2', 'wave': '0.1..01.01'}]

        Note the all the lanes should have the same number of samples.

        Parameters
        ----------
        trace_spec : dict
            A dictionary containing the trace specification.

        Returns
        -------
        list
            A list of dictionaries, each dictionary consisting the pin number,
            and the waveform pattern in string format.

        """

        if trace_spec is not None:
            self.trace_spec = trace_spec

        if self.trace_spec is None:
            raise TypeError(
                "Cannot use Trace Analyzer without a valid trace_spec.")

        trace_bit_width = self.trace_spec['monitor_width']
        trace_byte_width = round(trace_bit_width / 8)

        samples = self.intf.ndarray_from_buffer(
            'trace_buf', self.num_samples * trace_byte_width,
            dtype=BYTE_WIDTH_TO_NPTYPE[trace_byte_width])

        num_samples = len(samples)
        self.samples = np.zeros(num_samples, dtype='>i8')
        np.copyto(self.samples, samples)
        temp_bytes = np.frombuffer(self.samples, dtype=np.uint8)
        bit_array = np.unpackbits(temp_bytes)
        temp_lanes = bit_array.reshape(
            num_samples,
            self.trace_spec['monitor_width']).T[::-1]

        wavelanes = list()
        for pin_label in self.trace_spec['input_pin_map']:
            output_lane = temp_lanes[
                self.trace_spec['output_pin_map'][pin_label]]
            input_lane = temp_lanes[
                self.trace_spec['input_pin_map'][pin_label]]
            tri_lane = temp_lanes[
                self.trace_spec['tri_pin_map'][pin_label]]
            cond_list = [tri_lane == 0, tri_lane == 1]
            choice_list = [output_lane, input_lane]
            temp_lane = np.select(cond_list, choice_list)
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        return wavelanes
