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


from collections import OrderedDict
import numpy as np
from .constants import *
from .logictools_controller import LogicToolsController
from .waveform import bitstring_to_wave


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


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

    Since there is only one analyzer on the hardware, this class is 
    implemented as a singleton. All the generators will share this instance. 

    Attributes
    ----------
    logictools_controller : LogicToolsController
        The generator controller for this class.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_LOGICTOOLS_SPECIFICATION.
    num_analyzer_samples : int
        The number of samples to be analyzed.
    samples : numpy.ndarray
        The raw data samples expressed in numpy array.
    frequency_mhz: float
        The frequency of the trace analyzer, in MHz.

    """
    __instance = None
    __initialized = False

    def __new__(cls, mb_info, 
                intf_spec_name='PYNQZ1_LOGICTOOLS_SPECIFICATION'):
        """Create a new trace analyzer object.

        This method overwrites the default `new()` method so that the same
        instance can be reused by many modules. The internal variable 
        `__instance` is private and used as a singleton.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str
            The name of the interface specification.

        """
        if cls.__instance is None:
            cls.__instance = object.__new__(cls)
        return cls.__instance

    def __init__(self, mb_info, 
                 intf_spec_name='PYNQZ1_LOGICTOOLS_SPECIFICATION'):
        """Return a new trace analyzer object.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str
            The name of the interface specification.

        """
        if not self.__initialized:
            # Book-keep controller-related parameters
            self.logictools_controller = LogicToolsController(mb_info,
                                                              intf_spec_name)
            self.intf_spec = eval(intf_spec_name)
            self._mb_info = mb_info
            self._intf_spec_name = intf_spec_name

            # Parameters to be cleared at reset
            self.num_analyzer_samples = 0
            self.samples = None
            self.frequency_mhz = 0

            # Singleton related parameter
            self.__class__.__initialized = True

    def __repr__(self):
        """Disambiguation of the object.

        Users can call `repr(object_name)` to display the object information.

        """
        parameter_list = list()
        parameter_list.append('num_analyzer_samples={}'.format(
            self.num_analyzer_samples))
        parameter_list.append('frequency_mhz={}'.format(
            self.frequency_mhz))
        parameter_string = ", ".join(map(str, parameter_list))
        return '{}({})'.format(self.__class__.__name__, parameter_string)

    @property
    def status(self):
        """Return the generator's status.

        Returns
        -------
        str
            Indicating the current status of the analyzer; can be 
            'RESET', 'READY', or 'RUNNING'.

        """
        self.logictools_controller.check_status()
        return self.logictools_controller.status[self.__class__.__name__]

    def setup(self, num_analyzer_samples=DEFAULT_NUM_TRACE_SAMPLES,
              frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ):
        """Configure the trace analyzer.
        
        This method prepares the trace analyzer by sending configuration 
        parameters to the Microblaze.

        Note that the analyzer is always attached to the pins, so there
        is no need to use any method like 'connect()'. In short, once the 
        analyzer has been setup, it is connected as well.

        Note
        ----
        The first sample captured is a dummy sample (for both pattern 
        generator and FSM generator), therefore we have to allocate a buffer 
        one sample larger.

        Parameters
        ----------
        num_analyzer_samples : int
            The number of samples to be analyzed.
        frequency_mhz: float
            The frequency of the captured samples, in MHz.

        """
        if not 1 <= num_analyzer_samples <= MAX_NUM_TRACE_SAMPLES:
            raise ValueError('Number of samples should be in '
                             '[1, {}]'.format(MAX_NUM_TRACE_SAMPLES))
        self.num_analyzer_samples = num_analyzer_samples

        if not MIN_CLOCK_FREQUENCY_MHZ <= frequency_mhz <= \
                MAX_CLOCK_FREQUENCY_MHZ:
            raise ValueError("Clock frequency out of range "
                             "[{}, {}]".format(MIN_CLOCK_FREQUENCY_MHZ,
                                               MAX_CLOCK_FREQUENCY_MHZ))
        self.logictools_controller.clk.fclk1_mhz = frequency_mhz
        self.frequency_mhz = frequency_mhz

        trace_bit_width = self.intf_spec['monitor_width']
        trace_byte_width = round(trace_bit_width / 8)

        if 'trace_buf' in self.logictools_controller.buffers:
            buffer_phy_addr = self.logictools_controller.phy_addr_from_buffer(
                'trace_buf')
        else:
            buffer_phy_addr = self.logictools_controller.allocate_buffer(
                'trace_buf', 1 + self.num_analyzer_samples,
                data_type=BYTE_WIDTH_TO_CTYPE[trace_byte_width])

        self.logictools_controller.write_control([buffer_phy_addr,
                                                 1 + self.num_analyzer_samples,
                                                 0, 0])
        self.logictools_controller.write_command(CMD_CONFIG_TRACE)

        # Update generator status
        self.logictools_controller.check_status()

    def reset(self):
        """Reset the trace analyzer.

        This method will bring the trace analyzer from any state to 
        'RESET' state.

        """
        # Stop the running generator if necessary
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RUNNING':
            self.stop()

        # Clear the parameters
        self.num_analyzer_samples = 0
        self.samples = None
        self.frequency_mhz = 0

        # Send the reset command
        cmd_reset = CMD_RESET | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_reset)
        self.logictools_controller.check_status()

    def run(self):
        """Start the trace analyzer.

        This method will send the run command to the Microblaze.

        """
        cmd_run = CMD_RUN | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_run)
        self.logictools_controller.check_status()

    def step(self):
        """Step the trace analyzer.

        This method will send the step command to the Microblaze.

        """
        cmd_step = CMD_STEP | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_step)
        self.logictools_controller.check_status()

    def stop(self):
        """Stop the trace analyzer.

        This method will send the stop command to the Microblaze.

        """
        cmd_stop = CMD_STOP | TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_stop)
        self.logictools_controller.check_status()

    def __del__(self):
        """Clean up the object when it is no longer used.

        Contiguous memory buffers have to be freed.

        """
        self.logictools_controller.reset_buffers()
        self.__class__.__initialized = False

    def analyze(self, steps):
        """Analyze the captured pattern.

        This function will process the captured pattern and put the pattern
        into a Wavedrom compatible format.

        Each bit of the 20-bit patterns, from LSB to MSB, corresponds to:
        D0, D1, ..., D18 (A4), D19 (A5), respectively.

        The data output is of format:

        [{'name': '', 'pin': 'D1', 'wave': '1...0.....'},
         {'name': '', 'pin': 'D2', 'wave': '0.1..01.01'}]

        Note the all the lanes should have the same number of samples.

        Note
        ----
        The first sample captured is a dummy sample (for both pattern generator
        and FSM generator), therefore we have to discard the first sample.

        Parameters
        ----------
        steps : int
            Number of samples to analyze, if it is non-zero, it means the 
            generator is working in the `step()` mode.

        Returns
        -------
        list
            A list of dictionaries, each dictionary consisting the pin number,
            and the waveform pattern in string format.

        """
        tri_state_pins, non_tri_inputs, non_tri_outputs = \
            get_tri_state_pins(self.intf_spec['traceable_inputs'],
                               self.intf_spec['traceable_outputs'],
                               self.intf_spec['traceable_tri_states'])
        trace_bit_width = self.intf_spec['monitor_width']
        trace_byte_width = round(trace_bit_width / 8)

        samples = self.logictools_controller.ndarray_from_buffer(
            'trace_buf', (1 + self.num_analyzer_samples) * trace_byte_width,
            dtype=BYTE_WIDTH_TO_NPTYPE[trace_byte_width])

        # Exclude the first dummy sample when not in step()
        if steps == 0:
            num_valid_samples = len(samples) - 1
            self.samples = np.zeros(num_valid_samples, dtype='>i8')
            np.copyto(self.samples, samples[1:])
        else:
            num_valid_samples = 1
            self.samples = np.zeros(num_valid_samples, dtype='>i8')
            np.copyto(self.samples, samples[0])
        temp_bytes = np.frombuffer(self.samples, dtype=np.uint8)
        bit_array = np.unpackbits(temp_bytes)
        temp_lanes = bit_array.reshape(
            num_valid_samples,
            self.intf_spec['monitor_width']).T[::-1]

        wavelanes = list()
        # Adding tri-state captures
        for pin_label in tri_state_pins:
            output_lane = temp_lanes[
                self.intf_spec['traceable_outputs'][pin_label]]
            input_lane = temp_lanes[
                self.intf_spec['traceable_inputs'][pin_label]]
            tri_lane = temp_lanes[
                self.intf_spec['traceable_tri_states'][pin_label]]
            cond_list = [tri_lane == 0, tri_lane == 1]
            choice_list = [output_lane, input_lane]
            temp_lane = np.select(cond_list, choice_list)
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        # Adding non tri-state captures
        for pin_label in non_tri_inputs:
            temp_lane = temp_lanes[
                self.intf_spec['traceable_inputs'][pin_label]]
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        for pin_label in non_tri_outputs:
            temp_lane = temp_lanes[
                self.intf_spec['traceable_outputs'][pin_label]]
            bitstring = ''.join(temp_lane.astype(str).tolist())
            wave = bitstring_to_wave(bitstring)
            wavelanes.append({'name': '', 'pin': pin_label, 'wave': wave})

        return wavelanes
