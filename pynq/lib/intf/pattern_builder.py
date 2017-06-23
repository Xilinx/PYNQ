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
import numpy as np
from . import INTF_MICROBLAZE_BIN
from . import MAX_NUM_PATTERN_SAMPLES
from . import MAX_NUM_TRACE_SAMPLES
from . import IOSWITCH_PG_SELECT
from . import PYNQZ1_DIO_SPECIFICATION
from . import CMD_CONFIG_PG
from . import CMD_ARM_PG
from .intf import Intf
from .waveform import Waveform
from .trace_analyzer import TraceAnalyzer


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


def wave_to_bitstring(wave):
    """Function to convert a pattern consisting of `l`, `h`, and dot to a
    sequence of `0` and `1`.

    Parameters
    ----------
    wave : str
        The input string to convert.

    Returns
    -------
    str
        A bit sequence of 0's and 1's.

    """
    substitution_map = {'l': '0', 'h': '1'}

    def delete_dots(match):
        return substitution_map[match.group()[0]] * len(match.group())

    wave_regex = re.compile(r'[l]\.*|[h]\.*')
    return re.sub(wave_regex, delete_dots, wave)


def bitstring_to_int(bitstring):
    """Function to convert a bit string to integer list.

    For example, if the bit string is '0110', then the integer list will be
    [0,1,1,0].

    Parameters
    ----------
    bitstring : str
        The input string to convert.

    Returns
    -------
    list
        A list of elements, each element being 0 or 1.

    """
    return [int(i, 10) for i in list(bitstring)]


def int_to_sample(bits):
    """Function to convert a bit list into a multi-bit sample.

    Example: [1, 1, 1, 0] will be converted to 7, since the LSB of the 
    sample appears first in the sequence.

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


class PatternBuilder:
    """Class for the Pattern builder.

    This class can generate digital IO patterns / stimulus on output pins.
    Users can specify whether to use a pin as input or output.

    Attributes
    ----------
    intf : _INTF
        The interface Microblaze object used by this class.
    frequency_mhz: float
        The frequency of the running FSM / captured samples, in MHz.
    waveform : Waveform
        The Waveform object used for Wavedrom display.
    src_samples: numpy.ndarray
        The numpy array storing the stimuli, each sample being 32 bits.
    dst_samples: numpy.ndarray
        The numpy array storing the response, each sample being 64 bits.
    num_analyzer_samples : int
        The number of analyzer samples to capture.

    """
    def __init__(self, intf_microblaze, waveform_dict, frequency_mhz=10,
                 stimulus_name=None, analysis_name=None,
                 intf_spec=PYNQZ1_DIO_SPECIFICATION,
                 use_analyzer=True,
                 num_analyzer_samples=MAX_NUM_TRACE_SAMPLES):
        """Return a new pattern builder object.

        Parameters
        ----------
        intf_microblaze : Intf/dict
            The interface Microblaze object, or a dictionary storing 
            Microblaze information, such as the IP name and the reset name.
        waveform_dict : dict
            Waveform dictionary in WaveJSON format.
        frequency_mhz: float
            The frequency of the FSM and captured samples, in MHz.
        stimulus_name : str
            Name of the WaveLane group for the stimulus if used.
        analysis_name : str
            Name of the WaveLane group for the analysis if used.
        use_analyzer : bool
            Indicate whether to use the analyzer to capture the trace as well.
        num_analyzer_samples : int
            The number of analyzer samples to capture.

        """
        if isinstance(intf_microblaze, Intf):
            self.intf = intf_microblaze
        elif isinstance(intf_microblaze, dict):
            self.intf = Intf(intf_microblaze)
        else:
            raise TypeError(
                "Parameter intf_microblaze has to be intf.Intf or dict.")

        self.intf_spec = intf_spec
        self.frequency_mhz = 0
        self.stimulus_group = None
        self.stimulus_name = stimulus_name
        self.stimulus_names = None
        self.stimulus_pins = None
        self.stimulus_waves = None
        self.analysis_group = None
        self.analysis_name = analysis_name
        self.analysis_names = None
        self.analysis_pins = None
        self.src_samples = None
        self.dst_samples = None
        self.waveform_dict = None
        self.waveform = None
        self.num_analyzer_samples = num_analyzer_samples
        self._longest_wave = None
        self._max_wave_length = 0

        if use_analyzer:
            self.analyzer = TraceAnalyzer(
                self.intf, num_samples=num_analyzer_samples,
                trace_spec=intf_spec)
        else:
            self.analyzer = None

        self.config(waveform_dict, frequency_mhz)

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

    def _config_ioswitch(self):
        """Configure the IO switch.

        Will only be used internally. The method collects the pins used and 
        sends the list _INTF for handling.

        """
        # gather which pins are being used
        pg_pins = self.waveform.analysis_pins + self.waveform.stimulus_pins
        ioswitch_pins = [self.intf_spec['traceable_outputs'][pin]
                         for pin in pg_pins]

        # send list to _INTF processor for handling
        self.intf.config_ioswitch(ioswitch_pins, IOSWITCH_PG_SELECT)

    def config(self, waveform_dict, frequency_mhz=10):
        """Configure the PG with a single bit pattern.

        Generates a bit pattern for a single shot operation at specified IO 
        pins with the specified number of samples.

        Each bit of the 20-bit patterns, from LSB to MSB, corresponds to:
        D0, D1, ..., D19, A0, A1, ..., A5, respectively.

        Note the all the lanes should have the same number of samples. And the
        token inside wave are already converted into bit string.

        Users can ignore the returned data in case only the pattern
        builder is required.

        This method is called during initialization, but can also be called 
        separately if users want to change the waveform dictionary, or the
        frequency of the pattern generation / capture.

        Parameters
        ----------
        waveform_dict : dict
            Waveform dictionary in WaveJSON format.
        frequency_mhz: float
            The frequency of the captured samples, in MHz.

        Returns
        -------
        None

        """
        # Update Waveform based on waveform_dict
        self.waveform_dict = waveform_dict
        self.frequency_mhz = frequency_mhz
        self.waveform = Waveform(waveform_dict, 
                                 stimulus_name=self.stimulus_name,
                                 analysis_name=self.analysis_name)
        self.stimulus_group = self.waveform.stimulus_group
        self.analysis_group = self.waveform.analysis_group
        self.stimulus_names = self.waveform.stimulus_names
        self.stimulus_pins = self.waveform.stimulus_pins
        self.stimulus_waves = self.waveform.stimulus_waves
        self.analysis_names = self.waveform.analysis_names
        self.analysis_pins = self.waveform.analysis_pins

        if self.stimulus_name:
            self._longest_wave, self._max_wave_length = \
                self._get_max_wave_length()
        elif self.analysis_name:
            self._longest_wave, self._max_wave_length = \
                '', num_analyzer_samples
        else:
            raise ValueError("Must specify at least one "
                             "stimulus/analysis group.")
        self._make_same_wave_length()

        # Set other PG parameters
        self.intf.clk.fclk1_mhz = frequency_mhz
        self._config_ioswitch()

        direction_mask = 0xFFFFF
        num_samples = self._max_wave_length
        temp_lanes = np.zeros((self.intf_spec['interface_width'], num_samples),
                              dtype=np.uint8)

        # Prepare stimulus samples
        if self.stimulus_waves:
            data = self.stimulus_waves[:]
            for index, wave in enumerate(data):
                pin_number = self.intf_spec[
                    'traceable_outputs'][self.stimulus_pins[index]]
                direction_mask &= (~(1 << pin_number))
                temp_lanes[pin_number] = data[index] = bitstring_to_int(
                    wave_to_bitstring(wave))
            temp_samples = temp_lanes.T.copy()
            self.src_samples = np.apply_along_axis(
                int_to_sample, 1, temp_samples)

        # Allocate the source buffer
        src_addr = self.intf.allocate_buffer('src_buf', num_samples,
                                             data_type="unsigned int")

        # Write samples into the source buffer
        if self.src_samples is not None:
            for index, data in enumerate(self.src_samples):
                self.intf.buffers['src_buf'][index] = data

        # Wait for the interface processor to return control (1 : multiple)
        self.intf.write_control([direction_mask, src_addr, num_samples, 1])
        self.intf.write_command(CMD_CONFIG_PG)

        # configure the trace analyzer
        if self.analyzer is not None:
            self.analyzer.config()

        # Free the DRAM pattern buffer - pattern now in BRAM
        self.intf.free_buffer('src_buf')

    def arm(self):
        """Arm the pattern builder.
        
        This method will prepare the pattern builder.

        """
        self.intf.write_command(CMD_ARM_PG)

        if self.analyzer is not None:
            self.analyzer.arm()

    def is_armed(self):
        """Check if this builder's hardware is armed.

        Returns
        -------
        Bool
            True if the builder's hardware is armed.

        """
        return self.intf.armed_builders[CMD_ARM_PG]

    def start(self):
        """Run the pattern generation.

        This method will start to run the pattern generation.

        """
        if not self.is_armed():
            self.arm()

        self.intf.start()

    def stop(self, free_buffer=True):
        """Stop the pattern generation.
        
        This method will stop the currently running pattern generation.

        Parameters
        ----------
        free_buffer : Bool
            The flag indicating whether or not to free the analyzer buffer.

        """
        self.intf.stop(free_buffer)

    def show_waveform(self):
        """Display the waveform in Jupyter notebook.

        This method requires the waveform class to be present. At the same
        time, javascripts will be copied into the current directory. 

        """
        if self.analyzer:
            self.analysis_group = self.analyzer.analyze()
            self.waveform.update(self.analysis_name, self.analysis_group)
        else:
            raise ValueError("Trace disabled, please enable and rerun.")
        self.waveform.display()

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
        max_wave_length = 0
        name_of_longest_wave = ''
        for index, wave in enumerate(self.stimulus_waves):
            if len(wave) > max_wave_length:
                name_of_longest_wave = self.stimulus_names[index]
                max_wave_length = len(wave)

        if not 1 <= max_wave_length <= MAX_NUM_PATTERN_SAMPLES:
            raise ValueError(f"Waves should have 1 - "
                             f"{MAX_NUM_PATTERN_SAMPLES} samples.")
        return name_of_longest_wave, max_wave_length

    def _make_same_wave_length(self):
        """Set the all the waves to the same length.

        This method will pad the same tokens to the end of all the shorter
        waves. For example, if there are only 2 waves:
        'lhlhlh' (length of 6) and 'llhhllhh' (length of 8), while the number
        of analyzer samples is set to 8. Then the shorter
        one will be converted to: 'lhlhlhhh' (repeating the last token two
        more times).

        """
        if self.analyzer is not None:
            self._max_wave_length = max(self.num_analyzer_samples,
                                        self._max_wave_length)
        else:
            self._max_wave_length = self._max_wave_length

        for index, wave in enumerate(self.stimulus_waves):
            len_diff = self._max_wave_length - len(wave)
            if len_diff > 0:
                self.stimulus_waves[index] = wave + wave[-1] * len_diff
                print(f"WaveLane {self.stimulus_names[index]} extended to " +
                      f"{self._max_wave_length} tokens.")
