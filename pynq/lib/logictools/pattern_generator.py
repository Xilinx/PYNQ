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
from copy import deepcopy
import numpy as np
from .constants import *
from .logictools_controller import LogicToolsController
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


class PatternGenerator:
    """Class for the Pattern generator.

    This class can generate digital IO patterns / stimulus on output pins.
    Users can specify whether to use a pin as input or output.

    Attributes
    ----------
    logictools_controller : LogicToolsController
        The generator controller for this class.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_DIO_SPECIFICATION.
    stimulus_group : dict
        A group of stimulus wavelanes. 
    stimulus_group_name : str
        The name of the stimulus wavelanes.
    stimulus_names : list
        The list of all the stimulus wavelane names, each name being a string. 
    stimulus_pins : list
        The list of all the stimulus wavelane pin labels, each pin label 
        being a string.
    stimulus_waves : list
        The list of all the stimulus wavelane waves, each wave being a string
        consisting of wavelane tokens.
    analysis_group : dict
        A group of analysis wavelanes. 
    analysis_group_name : str
        The name of the analysis wavelanes.
    analysis_names : list
        The list of all the analysis wavelane names, each name being a string. 
    analysis_pins : list
        The list of all the analysis wavelane pin labels, each pin label 
        being a string.
    src_samples: numpy.ndarray
        The numpy array storing the stimuli, each sample being 32 bits.
    dst_samples: numpy.ndarray
        The numpy array storing the response, each sample being 64 bits.
    waveform_dict : dict
        A dictionary storing the patterns in WaveJason format.
    waveform : Waveform
        The Waveform object used for Wavedrom display.
    analyzer : TraceAnalyzer
        Analyzer to analyze the raw capture from the pins.
    num_analyzer_samples : int
        The number of analyzer samples to capture.
    frequency_mhz: float
        The frequency of the running generator / captured samples, in MHz.

    """
    def __init__(self, mb_info, intf_spec_name='PYNQZ1_DIO_SPECIFICATION'):
        """Return a new pattern generator object.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str
            The name of the interface specification.

        """
        # Book-keep controller-related parameters
        self.logictools_controller = LogicToolsController(mb_info,
                                                          intf_spec_name)
        self.intf_spec = eval(intf_spec_name)
        self._mb_info = mb_info
        self._intf_spec_name = intf_spec_name

        # Parameters to be cleared at reset
        self.stimulus_group = dict()
        self.stimulus_group_name = None
        self.stimulus_names = list()
        self.stimulus_pins = list()
        self.stimulus_waves = list()
        self.analysis_group = dict()
        self.analysis_group_name = None
        self.analysis_names = list()
        self.analysis_pins = list()
        self.frequency_mhz = 0
        self.src_samples = None
        self.dst_samples = None
        self.waveform_dict = dict()
        self.waveform = None
        self._longest_wave = None
        self._max_wave_length = 0

        # Trace analyzer will be attached by default
        self.analyzer = None
        self.num_analyzer_samples = 0
        self.trace()

    def __repr__(self):
        """Disambiguation of the object.

        Users can call `repr(object_name)` to display the object information.

        """
        parameter_list = list()
        parameter_list.append('num_analyzer_samples={}'.format(
            self.num_analyzer_samples))
        parameter_list.append('frequency_mhz={}'.format(
            self.frequency_mhz))
        parameter_list.append('stimulus_group_name={}'.format(
            self.stimulus_group_name))
        parameter_list.append('analysis_group_name={}'.format(
            self.analysis_group_name))
        parameter_string = ", ".join(map(str, parameter_list))
        return '{}({})'.format(self.__class__.__name__, parameter_string)

    @property
    def status(self):
        """Return the generator's status.

        Returns
        -------
        str
            Indicating the current status of the generator; can be 
            'RESET', 'READY', or 'RUNNING'.

        """
        self.logictools_controller.check_status()
        return self.logictools_controller.status[self.__class__.__name__]

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

    def trace(self, use_analyzer=True,
              num_analyzer_samples=MAX_NUM_TRACE_SAMPLES):
        """Configure the trace analyzer.

        By default, the trace analyzer is always on, unless users explicitly
        disable it.

        Parameters
        ----------
        use_analyzer : bool
            Whether to use the analyzer to capture the trace.
        num_analyzer_samples : int
            The number of analyzer samples to capture.

        """
        if use_analyzer:
            self.analyzer = TraceAnalyzer(self._mb_info,
                                          intf_spec_name=self._intf_spec_name)
            self.num_analyzer_samples = num_analyzer_samples
        else:
            if self.analyzer is not None:
                self.analyzer.__del__()
            self.analyzer = None
            self.num_analyzer_samples = 0

    def setup(self, waveform_dict,
              stimulus_group_name=None, analysis_group_name=None,
              frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ):
        """Configure the pattern generator with a single bit pattern.

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
        waveform_dict : dict
            Waveform dictionary in WaveJSON format.
        stimulus_group_name : str
            Name of the WaveLane group for the stimulus if used.
        analysis_group_name : str
            Name of the WaveLane group for the analysis if used.
        frequency_mhz: float
            The frequency of the captured samples, in MHz.

        """
        if not MIN_CLOCK_FREQUENCY_MHZ <= frequency_mhz <= \
                MAX_CLOCK_FREQUENCY_MHZ:
            raise ValueError("Clock frequency out of range "
                             "[{}, {}]".format(MIN_CLOCK_FREQUENCY_MHZ,
                                               MAX_CLOCK_FREQUENCY_MHZ))

        # Update Waveform based on waveform_dict
        self.stimulus_group_name = stimulus_group_name
        self.analysis_group_name = analysis_group_name
        self.waveform_dict = deepcopy(waveform_dict)
        self.waveform = Waveform(waveform_dict, 
                                 stimulus_group_name=stimulus_group_name,
                                 analysis_group_name=analysis_group_name)
        self.stimulus_group = self.waveform.stimulus_group
        self.analysis_group = self.waveform.analysis_group
        self.stimulus_names = self.waveform.stimulus_names
        self.stimulus_pins = self.waveform.stimulus_pins
        self.stimulus_waves = self.waveform.stimulus_waves
        self.analysis_names = self.waveform.analysis_names
        self.analysis_pins = self.waveform.analysis_pins

        if self.stimulus_group_name:
            self._longest_wave, self._max_wave_length = \
                self._get_max_wave_length()
        elif self.analysis_group_name:
            self._longest_wave, self._max_wave_length = \
                '', self.num_analyzer_samples
        else:
            raise ValueError("Must specify at least one "
                             "stimulus/analysis group.")
        self._make_same_wave_length()

        # Check used pins on the controller
        for i in self.stimulus_pins + self.analysis_pins:
            if self.logictools_controller.pin_map[i] != 'UNUSED':
                raise ValueError(
                    "Pin conflict: {} already in use.".format(
                        self.logictools_controller.pin_map[i]))

        # Reserve pins only if there are no conflicts for any pin
        for i in self.stimulus_pins:
            self.logictools_controller.pin_map[i] = 'OUTPUT'
        for i in self.analysis_pins:
            self.logictools_controller.pin_map[i] = 'INPUT'

        # Prepare stimulus samples
        direction_mask = 0xFFFFF
        num_valid_samples = self._max_wave_length
        temp_lanes = np.zeros((self.intf_spec['interface_width'],
                               num_valid_samples), dtype=np.uint8)
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
        src_addr = self.logictools_controller.allocate_buffer(
            'src_buf', 1 + num_valid_samples, data_type="unsigned int")

        # Write samples into source buffer, including the 1st dummy sample
        if self.src_samples is not None:
            self.logictools_controller.buffers['src_buf'][0] = 0
            for index, data in enumerate(self.src_samples):
                self.logictools_controller.buffers['src_buf'][index + 1] = data

        # Wait for the Microblaze processor to return control (1 : multiple)
        self.logictools_controller.write_control([direction_mask, src_addr,
                                                 1 + num_valid_samples, 1])
        self.logictools_controller.write_command(CMD_CONFIG_PATTERN)

        # Configure the trace analyzer and frequency
        if self.analyzer is not None:
            self.analyzer.setup(self.num_analyzer_samples,
                                frequency_mhz)
        else:
            self.logictools_controller.clk.fclk1_mhz = frequency_mhz
        self.frequency_mhz = frequency_mhz

        # Free the DRAM pattern buffer - pattern now in BRAM
        self.logictools_controller.free_buffer('src_buf')

        # Update generator status
        self.logictools_controller.check_status()

    def reset(self):
        """Reset the pattern generator.

        This method will bring the generator from any state to 
        'RESET' state.

        """
        # Stop the running generator if necessary
        self.stop()

        # Clear all the reserved pins
        for i in self.stimulus_pins + self.analysis_pins:
            self.logictools_controller.pin_map[i] = 'UNUSED'

        self.frequency_mhz = 0
        self.stimulus_group.clear()
        self.stimulus_group_name = None
        self.stimulus_names.clear()
        self.stimulus_pins.clear()
        self.stimulus_waves.clear()
        self.analysis_group.clear()
        self.analysis_group_name = None
        self.analysis_names.clear()
        self.analysis_pins.clear()
        self.src_samples = None
        self.dst_samples = None
        self.waveform_dict.clear()
        self.waveform = None
        self._longest_wave = None
        self._max_wave_length = 0

        # Send the reset command
        cmd_reset = CMD_RESET | PATTERN_ENGINE_BIT
        if self.analyzer is not None:
            cmd_reset |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_reset)
        self.logictools_controller.check_status()

    def connect(self):
        """Method to configure the IO switch.

        Usually this method should only be used internally. Users only need
        to use `run()` method.

        """
        # Gather which pins are being used
        pattern_pins = self.analysis_pins + self.stimulus_pins
        ioswitch_pins = [self.intf_spec['traceable_outputs'][pin]
                         for pin in pattern_pins]

        # Send list to Microblaze processor for handling
        self.logictools_controller.config_ioswitch(ioswitch_pins,
                                                   IOSWITCH_PATTERN_SELECT)

    def disconnect(self):
        """Method to disconnect the IO switch.

        Usually this method should only be used internally. Users only need
        to use `stop()` method.

        """
        # Gather which pins are being used
        pattern_pins = self.analysis_pins + self.stimulus_pins
        ioswitch_pins = [self.intf_spec['traceable_outputs'][pin]
                         for pin in pattern_pins]

        # Send list to Microblaze processor for handling
        self.logictools_controller.config_ioswitch(ioswitch_pins,
                                                   IOSWITCH_DISCONNECT)

    def run(self):
        """Run the pattern generation.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to run the pattern 
        generator.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RESET':
            raise ValueError(
                "Generator must be at least READY before RUNNING.")
        self.connect()
        cmd_run = CMD_RUN | PATTERN_ENGINE_BIT
        if self.analyzer is not None:
            cmd_run |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_run)
        self.logictools_controller.check_status()

    def step(self):
        """Step the pattern generator.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to step the pattern 
        generator.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RESET':
            raise ValueError(
                "Generator must be at least READY before RUNNING.")
        self.connect()
        cmd_step = CMD_STEP | PATTERN_ENGINE_BIT
        if self.analyzer is not None:
            cmd_step |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_step)
        self.logictools_controller.check_status()

    def stop(self):
        """Stop the pattern generation.
        
        This method will stop the currently running pattern generator.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RUNNING':
            cmd_stop = CMD_STOP | PATTERN_ENGINE_BIT
            if self.analyzer is not None:
                cmd_stop |= TRACE_ENGINE_BIT
            self.logictools_controller.write_command(cmd_stop)
            self.disconnect()
            self.logictools_controller.check_status()

    def show_waveform(self):
        """Display the waveform in Jupyter notebook.

        This method requires the waveform class to be present. At the same
        time, javascripts will be copied into the current directory. 

        """
        if self.analyzer is None:
            raise ValueError("Trace disabled, please enable and rerun.")

        self.analysis_group = self.analyzer.analyze()
        self.waveform.update(self.analysis_group_name, self.analysis_group)
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
            raise ValueError("Waves should have 1 - "
                             "{} samples.".format(MAX_NUM_PATTERN_SAMPLES))
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
        self._max_wave_length = max(self.num_analyzer_samples,
                                    self._max_wave_length)

        for index, wave in enumerate(self.stimulus_waves):
            len_diff = self._max_wave_length - len(wave)
            if len_diff > 0:
                self.stimulus_waves[index] = wave + wave[-1] * len_diff
                print("WaveLane {} extended to {} tokens.".format(
                    self.stimulus_names[index], self._max_wave_length))

    def __del__(self):
        """Delete the instance.

        Need to reset the buffers used in this instance.

        """
        if self.analyzer:
            self.analyzer.__del__()
