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


import re
from collections import OrderedDict
import numpy as np
from . import INTF_MICROBLAZE_BIN
from . import CMD_CONFIG_TRACE
from . import BYTE_WIDTH_TO_CTYPE
from . import CMD_ARM_TRACE
from . import BYTE_WIDTH_TO_NPTYPE
from . import MAX_NUM_TRACE_SAMPLES
from .intf import Intf


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


def get_tri_state_pins(input_dict, output_dict, tri_dict):
    """Function to check tri-state pin specifications.

    Any tri-state pin requires the output pin, input pin, and the tri-state
    selection pin to be specified. If any one is missing, this method will
    raise an exception.

    Parameters
    ----------
    input_dict : dict
        A dictionary storing the input pin mapping.
    output_dict : dict
        A dictionary storing the output pin mapping.
    tri_dict : dict
        A dictionary storing the tri-state pin mapping.

    Returns
    -------
    list, list, list
        A list storing unique tri-state pin names, non tri-state inputs, and
        non tri-state outputs.

    """
    input_pins = list(OrderedDict.fromkeys(input_dict.keys()))
    output_pins = list(OrderedDict.fromkeys(output_dict.keys()))
    tri_pins = list(OrderedDict.fromkeys(tri_dict.keys()))
    if not set(tri_pins) & set(input_pins) == \
            set(tri_pins) & set(output_pins) == set(tri_pins):
        raise ValueError("Tri-state pins must specify inputs, "
                         "outputs, and tri-states.")

    non_tri_inputs = [i for i in input_pins if i not in tri_pins]
    non_tri_outputs = [i for i in output_pins if i not in tri_pins]
    return tri_pins, non_tri_inputs, non_tri_outputs


class TraceAnalyzer:
    """Class for the Trace Analyzer.

    This class can capture digital IO patterns / stimulus on all the pins.
    When a pin is specified as input, the response can be captured.

    Attributes
    ----------
    intf : Intf
        The interface Microblaze object used by this class.
    trace_spec : dict
        The trace spec of similar format as PYNQZ1_DIO_SPECIFICATION.
    num_samples : int
        The number of samples to be analyzed.
    samples : numpy.ndarray
        The raw data samples expressed in numpy array.

    """
    def __init__(self, intf_microblaze, num_samples=MAX_NUM_TRACE_SAMPLES,
                 trace_spec=None):
        """Return a new trace analyzer object.

        Parameters
        ----------
        intf_microblaze : Intf/dict
            The interface Microblaze object, or a dictionary storing 
            Microblaze information, such as the IP name and the reset name.
        num_samples : int
            The number of samples to be analyzed.
        trace_spec : dict
            The trace spec of similar format as PYNQZ1_DIO_SPECIFICATION.

        """
        if isinstance(intf_microblaze, Intf):
            self.intf = intf_microblaze
        elif isinstance(intf_microblaze, dict):
            self.intf = Intf(intf_microblaze)
        else:
            raise TypeError(
                "Parameter intf_microblaze has to be intf.Intf or dict.")

        if not 1 <= num_samples <= MAX_NUM_TRACE_SAMPLES:
            raise ValueError(f'Number of samples should be in '
                             f'[1, {MAX_NUM_TRACE_SAMPLES}]')

        self.trace_spec = trace_spec
        self.num_samples = num_samples
        self.samples = None
        self.config()

    def config(self):
        """Configure the trace analyzer.
        
        This method prepares the trace analyzer by sending configuration 
        parameters to the intf Microblaze.

        This method is called during initialization, but can also be called 
        separately if users want to reconfigure the trace buffer.

        """
        # Get width in bytes and send to allocator held with intf Microblaze
        trace_bit_width = self.trace_spec['monitor_width']
        trace_byte_width = round(trace_bit_width / 8)

        if 'trace_buf' in self.intf.buffers:
            buffer_phy_addr = self.intf.phy_addr_from_buffer('trace_buf')
        else:
            buffer_phy_addr = self.intf.allocate_buffer(
                'trace_buf', self.num_samples,
                data_type=BYTE_WIDTH_TO_CTYPE[trace_byte_width])

        self.intf.write_control([buffer_phy_addr, self.num_samples, 0, 0])
        self.intf.write_command(CMD_CONFIG_TRACE)

    def arm(self):
        """Arm the analyzer.

        This method prepares the trace analyzer before analyzing samples.

        """
        self.intf.write_command(CMD_ARM_TRACE)

    def is_armed(self):
        """Check if this builder's hardware is armed.

        Returns
        -------
        Bool
            True if the builder's hardware is armed.

        """
        return self.intf.armed_builders[CMD_ARM_TRACE]

    def start(self):
        """Start the pattern analysis.

        This method will send the start command to the intf Microblaze.

        """
        if not self.is_armed():
            self.arm()

        self.intf.start()

    def stop(self, free_buffer=True):
        """Stop the pattern analysis.

        This method will send the stop command to the intf Microblaze.

        This method can also free the analyzer buffer after use.

        Parameters
        ----------
        free_buffer : Bool
            The flag indicating whether or not to free the analyzer buffer.

        """
        self.intf.stop(free_buffer)

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
        tri_state_pins, non_tri_inputs, non_tri_outputs = \
            get_tri_state_pins(self.trace_spec['traceable_inputs'],
                               self.trace_spec['traceable_outputs'],
                               self.trace_spec['traceable_tri_states'])
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
        # Adding tri-state captures
        for pin_label in tri_state_pins:
            output_lane = temp_lanes[
                self.trace_spec['traceable_outputs'][pin_label]]
            input_lane = temp_lanes[
                self.trace_spec['traceable_inputs'][pin_label]]
            tri_lane = temp_lanes[
                self.trace_spec['traceable_tri_states'][pin_label]]
            cond_list = [tri_lane == 0, tri_lane == 1]
            choice_list = [output_lane, input_lane]
            temp_lane = np.select(cond_list, choice_list)
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        # Adding non tri-state captures
        for pin_label in non_tri_inputs:
            temp_lane = temp_lanes[
                self.trace_spec['traceable_inputs'][pin_label]]
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        for pin_label in non_tri_outputs:
            temp_lane = temp_lanes[
                self.trace_spec['traceable_outputs'][pin_label]]
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        return wavelanes
