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
from collections import OrderedDict
from pynq import Register
from .constants import *
from .logictools_controller import LogicToolsController
from .trace_analyzer import TraceAnalyzer
from .waveform import Waveform


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


class BooleanGenerator:
    """Class for the Boolean generator.

    This class can implement any combinational function on user IO pins. Since
    each LUT5 takes 5 inputs, the basic function that users can implement is
    5-input, 1-output boolean function. However, by concatenating multiple
    LUT5 together, users can implement complex boolean functions.

    There are 20 5-LUTs, so users can implement at most 20 basic boolean 
    functions at a specific time.

    Attributes
    ----------
    logictools_controller : LogicToolsController
        The generator controller for this class.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_LOGICTOOLS_SPECIFICATION.
    expressions : list/dict
        The boolean expressions, each expression being a string.
    waveforms : dict
        A dictionary storing the waveform objects for display purpose.
    input_pins : list
        A list of input pins used by the generator.
    output_pins : list
        A list of output pins used by the generator.
    analyzer : TraceAnalyzer
        Analyzer to analyze the raw capture from the pins.
    num_analyzer_samples : int
        Number of analyzer samples to capture.
    frequency_mhz: float
        The frequency of the captured samples, in MHz.

    """
    def __init__(self, mb_info,
                 intf_spec_name='PYNQZ1_LOGICTOOLS_SPECIFICATION'):
        """Return a new Boolean generator object.
        
        For ARDUINO, the available input pins are data pins D0 - D19,
        and the onboard push buttons PB0 - PB3. 

        The available output pins can be D0-D19.

        Note that D14 is A0, D15 is A1, ..., and D19 is A5 on the header.

        The input boolean expression can be of the following format:
        `D4 = D0 & D1 | D2`.

        If no input boolean expression is specified, the default function
        implemented is `D0 & D1 & D2 & D3`.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        intf_spec_name : str/dict
            The name of the interface specification.

        """
        # Book-keep controller-related parameters
        self.logictools_controller = LogicToolsController(mb_info,
                                                          intf_spec_name)
        if type(intf_spec_name) is str:
            self.intf_spec = eval(intf_spec_name)
        elif type(intf_spec_name) is dict:
            self.intf_spec = intf_spec_name
        else:
            raise ValueError("Interface specification has to be str or dict.")
        self._mb_info = mb_info

        # Parameters to be cleared at reset
        self.expressions = dict()
        self.output_pins = list()
        self.input_pins = list()
        self.waveforms = dict()
        self.frequency_mhz = 0

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

    def trace(self, use_analyzer=True,
              num_analyzer_samples=DEFAULT_NUM_TRACE_SAMPLES):
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
                                          intf_spec_name=self.intf_spec)
            self.num_analyzer_samples = num_analyzer_samples
        else:
            if self.analyzer is not None:
                self.analyzer.__del__()
            self.analyzer = None
            self.num_analyzer_samples = 0

    def setup(self, expressions, frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ):
        """Configure the generator with new boolean expression.

        This method will bring the generator from 'RESET' to 
        'READY' state.

        Parameters
        ----------
        expressions : list/dict
            The boolean expression to be configured.
        frequency_mhz: float
            The frequency of the captured samples, in MHz.

        """
        try:
            from pyeda.inter import exprvar
            from pyeda.inter import expr2truthtable
        except ImportError:
            raise ImportError("Using Logictools requires pyeda")

        if not MIN_CLOCK_FREQUENCY_MHZ <= frequency_mhz <= \
                MAX_CLOCK_FREQUENCY_MHZ:
            raise ValueError("Clock frequency out of range "
                             "[{}, {}]".format(MIN_CLOCK_FREQUENCY_MHZ,
                                               MAX_CLOCK_FREQUENCY_MHZ))

        if not 1 <= len(expressions) <= self.intf_spec['interface_width'] + \
                len(self.intf_spec['non_traceable_outputs']):
            raise ValueError("Too many or no Boolean expressions specified.")

        if isinstance(expressions, list):
            for i in range(len(expressions)):
                self.expressions['Boolean expression {}'.format(i)] = \
                    deepcopy(expressions[i])
        elif isinstance(expressions, dict):
            self.expressions = deepcopy(expressions)
        else:
            raise ValueError("Expressions must be list or dict.")

        mailbox_addr = self.logictools_controller.mmio.base_addr + \
            MAILBOX_OFFSET
        mailbox_regs = [Register(addr) for addr in range(
            mailbox_addr, mailbox_addr + 4 * 64, 4)]
        for offset in range(0, 48, 2):
            mailbox_regs[offset][31:0] = 0x1FFFFFF

        for expr_label, expression in self.expressions.items():
            if not isinstance(expression, str):
                raise TypeError("Boolean expression has to be a string.")

            if "=" not in expression:
                raise ValueError(
                    "Boolean expression must have form Output = Function.")

            # Parse boolean expression into output & input string
            expr_out, expr_in = expression.split("=")
            expr_out = expr_out.strip()
            if expr_out in self.output_pins:
                raise ValueError("The same output pin should not be driven by "
                                 "multiple expressions.")
            self.output_pins.append(expr_out)
            if expr_out in self.intf_spec['traceable_io_pins']:
                output_pin_num = self.intf_spec[
                    'traceable_io_pins'][expr_out]
            elif expr_out in self.intf_spec['non_traceable_outputs']:
                output_pin_num = self.intf_spec[
                    'non_traceable_outputs'][expr_out]
            else:
                raise ValueError("Invalid output pin {}.".format(expr_out))

            # Parse the used pins preserving the order
            non_unique_inputs = re.sub("\W+", " ", expr_in).strip().split(' ')
            unique_input_pins = list(OrderedDict.fromkeys(non_unique_inputs))
            if not 1 <= len(unique_input_pins) <= 5:
                raise ValueError("Expect 1 - 5 inputs for each LUT.")
            input_pins_with_dontcares = unique_input_pins[:]
            self.input_pins += unique_input_pins
            self.input_pins = list(set(self.input_pins))

            # Need 5 inputs - any unspecified inputs will be don't cares
            for i in range(len(input_pins_with_dontcares), 5):
                expr_in = '(({0}) & X{1})|(({0}) & ~X{1})'.format(
                    expr_in, i)
                input_pins_with_dontcares.append('X{}'.format(i))

            # Map to truth table
            p0, p1, p2, p3, p4 = map(exprvar, input_pins_with_dontcares)
            expr_p = expr_in

            # Use regular expression to match and replace whole word only
            for orig_name, p_name in zip(input_pins_with_dontcares,
                                         ['p{}'.format(i) for i in range(5)]):
                expr_p = re.sub(r"\b{}\b".format(orig_name), p_name, expr_p)

            truth_table = expr2truthtable(eval(expr_p))

            # Parse truth table to send
            truth_list = str(truth_table).split("\n")
            truth_num = 0
            for i in range(32, 0, -1):
                truth_num = (truth_num << 1) + int(truth_list[i][-1])

            # Get current boolean generator bit enables
            self.logictools_controller.write_command(
                CMD_READ_BOOLEAN_DIRECTION)
            bit_enables = mailbox_regs[0][31:0]

            # Generate the input selects based on truth table and bit enables
            truth_table_inputs = [str(inp) for inp in truth_table.inputs]
            for i in range(5):
                lsb = i * 5
                msb = (i + 1) * 5 - 1
                if truth_table_inputs[i] in unique_input_pins:
                    if truth_table_inputs[i] in self.intf_spec[
                        'traceable_io_pins'] and truth_table_inputs[i] \
                            in self.intf_spec['traceable_io_pins']:
                        input_pin_ix = self.intf_spec[
                            'traceable_io_pins'][truth_table_inputs[i]]
                    elif truth_table_inputs[i] in self.intf_spec[
                            'non_traceable_inputs']:
                        input_pin_ix = self.intf_spec[
                            'non_traceable_inputs'][truth_table_inputs[i]]
                    else:
                        raise ValueError("Invalid input pin "
                                         "{}.".format(truth_table_inputs[i]))
                else:
                    input_pin_ix = 0x1f
                mailbox_regs[output_pin_num * 2][msb:lsb] = input_pin_ix

            mailbox_regs[output_pin_num * 2 + 1][31:0] = truth_num
            mailbox_regs[62][31:0] = bit_enables
            mailbox_regs[62][output_pin_num] = 0

            mailbox_regs[63][31:0] = 0
            mailbox_regs[63][output_pin_num] = 1

            # Construct the command word
            self.logictools_controller.write_command(CMD_CONFIG_BOOLEAN)

            # Prepare the waveform object
            waveform_dict = {'signal': [
                ['stimulus'],
                {},
                ['analysis']],
                'head': {'text': '{}: {}'.format(expr_label, expression)}}

            # Append four inputs and one output to waveform view
            stimulus_traced = False
            for pin_name in unique_input_pins:
                if pin_name in self.intf_spec['traceable_io_pins']:
                    stimulus_traced = True
                    waveform_dict['signal'][0].append({'name': pin_name,
                                                       'pin': pin_name})
            if not stimulus_traced:
                del (waveform_dict['signal'][0])

            if expr_out in self.intf_spec['traceable_io_pins']:
                waveform_dict['signal'][-1].append({'name': expr_out,
                                                    'pin': expr_out})
            else:
                del (waveform_dict['signal'][-1])

            self.waveforms[expr_label] = Waveform(
                waveform_dict,
                stimulus_group_name='stimulus',
                analysis_group_name='analysis')

        # Check used pins on the controller
        for i in self.input_pins + self.output_pins:
            if self.logictools_controller.pin_map[i] != 'UNUSED':
                raise ValueError(
                    "Pin conflict: {} already in use.".format(
                        self.logictools_controller.pin_map[i]))

        # Reserve pins only if there are no conflicts for any pin
        for i in self.output_pins:
            self.logictools_controller.pin_map[i] = 'OUTPUT'
        for i in self.input_pins:
            self.logictools_controller.pin_map[i] = 'INPUT'

        # Configure the trace analyzer and frequency
        if self.analyzer is not None:
            self.analyzer.setup(self.num_analyzer_samples,
                                frequency_mhz)
        else:
            self.logictools_controller.clk.fclk1_mhz = frequency_mhz
        self.frequency_mhz = frequency_mhz

        # Update generator status
        self.logictools_controller.check_status()
        self.logictools_controller.steps = 0

    def reset(self):
        """Reset the boolean generator.

        This method will bring the generator from any state to 
        'RESET' state.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RUNNING':
            self.stop()

        for i in self.output_pins + self.input_pins:
            self.logictools_controller.pin_map[i] = 'UNUSED'

        self.expressions.clear()
        self.output_pins.clear()
        self.input_pins.clear()
        self.waveforms.clear()
        self.frequency_mhz = 0

        cmd_reset = CMD_RESET | BOOLEAN_ENGINE_BIT
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
        ioswitch_pins = list()
        ioswitch_pins += [self.intf_spec['traceable_io_pins'][input_pin]
                          for input_pin in self.input_pins
                          if input_pin in self.intf_spec['traceable_io_pins']]
        ioswitch_pins += [self.intf_spec['traceable_io_pins'][output_pin]
                          for output_pin in self.output_pins
                          if output_pin in self.intf_spec['traceable_io_pins']]

        # Send list to Microblaze processor for handling
        self.logictools_controller.config_ioswitch(ioswitch_pins,
                                                   IOSWITCH_BOOLEAN_SELECT)

    def disconnect(self):
        """Method to disconnect the IO switch.

        Usually this method should only be used internally. Users only need
        to use `stop()` method.

        """
        # Gather which pins are being used
        ioswitch_pins = list()
        ioswitch_pins += [self.intf_spec['traceable_io_pins'][input_pin]
                          for input_pin in self.input_pins
                          if input_pin in self.intf_spec['traceable_io_pins']]
        ioswitch_pins += [self.intf_spec['traceable_io_pins'][output_pin]
                          for output_pin in self.output_pins
                          if output_pin in self.intf_spec['traceable_io_pins']]

        # Send list to Microblaze processor for handling
        self.logictools_controller.config_ioswitch(ioswitch_pins,
                                                   IOSWITCH_DISCONNECT)

    def run(self):
        """Run the boolean generator.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to run the boolean 
        generator.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RESET':
            raise ValueError(
                "Generator must be at least READY before RUNNING.")
        self.connect()
        self.logictools_controller.steps = 0

        cmd_run = CMD_RUN | BOOLEAN_ENGINE_BIT
        if self.analyzer is not None:
            cmd_run |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_run)
        self.logictools_controller.check_status()
        self.analyze()

    def step(self):
        """Step the boolean generator.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to step the boolean 
        generator.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] == 'RESET':
            raise ValueError(
                "Generator must be at least READY before RUNNING.")

        if self.logictools_controller.steps == 0:
            self.connect()
            cmd_step = CMD_STEP | BOOLEAN_ENGINE_BIT
            if self.analyzer is not None:
                cmd_step |= TRACE_ENGINE_BIT
            self.logictools_controller.write_command(cmd_step)
        self.logictools_controller.steps += 1

        cmd_step = CMD_STEP | BOOLEAN_ENGINE_BIT
        if self.analyzer is not None:
            cmd_step |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_step)
        self.logictools_controller.check_status()
        self.analyze()

    def analyze(self):
        """Update the captured samples.

        This method updates the captured samples from the trace analyzer.
        It is required after each step() / run()

        """
        if self.analyzer is not None:
            analysis_group = self.analyzer.analyze(
                self.logictools_controller.steps)
            for expr_label in self.expressions.keys():
                if self.logictools_controller.steps:
                    self.waveforms[expr_label].append('stimulus',
                                                      analysis_group)
                    self.waveforms[expr_label].append('analysis',
                                                      analysis_group)
                else:
                    self.waveforms[expr_label].update('stimulus',
                                                      analysis_group)
                    self.waveforms[expr_label].update('analysis',
                                                      analysis_group)

    def stop(self):
        """Stop the boolean generator.

        This method will stop the currently running boolean generator.

        """
        cmd_stop = CMD_STOP | BOOLEAN_ENGINE_BIT
        if self.analyzer is not None:
            cmd_stop |= TRACE_ENGINE_BIT
        self.logictools_controller.write_command(cmd_stop)
        self.disconnect()
        self.logictools_controller.check_status()
        self.clear_wave()
        self.logictools_controller.steps = 0

    def clear_wave(self):
        """Clear the waveform object so new patterns can be accepted.

        This function is required after each `stop()`.

        """
        for expr_label in self.expressions.keys():
            if expr_label in self.waveforms and self.waveforms[expr_label]:
                self.waveforms[expr_label].clear_wave('stimulus')
                self.waveforms[expr_label].clear_wave('analysis')

    def show_waveform(self):
        """Display the boolean logic generator in a Jupyter notebook.

        A wavedrom waveform is shown with all inputs and outputs displayed.

        """
        if self.analyzer is None:
            raise ValueError("Trace disabled, please enable and rerun.")

        for expr_label in self.expressions.keys():
            if 0 < self.logictools_controller.steps < 3:
                for key in self.waveforms[expr_label].waveform_dict:
                    for annotation in ['tick', 'tock']:
                        if annotation in self.waveforms[
                                expr_label].waveform_dict[key]:
                            del self.waveforms[
                                expr_label].waveform_dict[key][annotation]
            else:
                self.waveforms[expr_label].waveform_dict['foot'] = {'tock': 1}
            self.waveforms[expr_label].display()

    def __del__(self):
        """Delete the instance.

        Need to reset the buffers used in this instance.

        """
        if self.logictools_controller.status[
                self.__class__.__name__] != 'RESET':
            self.reset()
            self.logictools_controller.check_status()
        if self.analyzer:
            self.analyzer.__del__()
