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
from pyeda.inter import exprvar
from pyeda.inter import expr2truthtable
from pynq import Register
from .constants import *
from .builder_controller import BuilderController
from .trace_analyzer import TraceAnalyzer
from .waveform import Waveform


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


class BooleanBuilder:
    """Class for the Boolean builder.

    This class can implement any combinational function on user IO pins. Since
    each LUT5 takes 5 inputs, the basic function that users can implement is
    5-input, 1-output boolean function. However, by concatenating multiple
    LUT5 together, users can implement complex boolean functions.

    There are 20 5-LUTs, so users can implement at most 20 basic boolean 
    functions at a specific time.

    Attributes
    ----------
    builder_controller : BuilderController
        The builder controller for this class.
    intf_spec : dict
        The interface specification, e.g., PYNQZ1_DIO_SPECIFICATION.
    expressions : list/dict
        The boolean expressions, each expression being a string.
    waveforms : dict
        A dictionary storing the waveform objects for display purpose.
    input_pins : list
        A list of input pins used by the builder.
    output_pins : list
        A list of output pins used by the builder.
    analyzer : TraceAnalyzer
        Analyzer to analyze the raw capture from the pins.
    num_analyzer_samples : int
        Number of analyzer samples to capture.
    frequency_mhz: float
        The frequency of the FSM and captured samples, in MHz.

    """
    def __init__(self, mb_info, intf_spec_name='PYNQZ1_DIO_SPECIFICATION'):
        """Return a new Boolean builder object.
        
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
        intf_spec_name : str
            The name of the interface specification.

        """
        # Book-keep controller-related parameters
        self.builder_controller = BuilderController(mb_info, intf_spec_name)
        self.intf_spec = eval(intf_spec_name)
        self._mb_info = mb_info
        self._intf_spec_name = intf_spec_name

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
        parameter_list.append(f'num_analyzer_samples='
                              f'{self.num_analyzer_samples}')
        parameter_list.append(f'frequency_mhz='
                              f'{self.frequency_mhz}')
        parameter_string = ", ".join(map(str, parameter_list))
        return f'{self.__class__.__name__}({parameter_string})'

    @property
    def status(self):
        """Return the builder's status.

        Returns
        -------
        str
            Indicating the current status of the builder; can be 
            'RESET', 'READY', or 'RUNNING'.

        """
        self.builder_controller.check_status()
        return self.builder_controller.status[self.__class__.__name__]

    def trace(self, use_analyzer=True, num_analyzer_samples=16):
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
            self.analyzer = None
            self.num_analyzer_samples = 0

    def setup(self, expressions, frequency_mhz=DEFAULT_CLOCK_FREQUENCY_MHZ):
        """Configure the builder with new boolean expression.

        This method will bring the builder from 'RESET' to 
        'READY' state.

        Parameters
        ----------
        expressions : list/dict
            The boolean expression to be configured.
        frequency_mhz: float
            The frequency of the FSM and captured samples, in MHz.

        """
        if not MIN_CLOCK_FREQUENCY_MHZ <= frequency_mhz <= \
                MAX_CLOCK_FREQUENCY_MHZ:
            raise ValueError(f"Clock frequency out of range "
                             f"[{MIN_CLOCK_FREQUENCY_MHZ}, "
                             f"{MAX_CLOCK_FREQUENCY_MHZ}]")

        if not 1 <= len(expressions) <= self.intf_spec['interface_width'] + \
                len(self.intf_spec['non_traceable_outputs']):
            raise ValueError("Too many Boolean expressions to implement.")

        if isinstance(expressions, list):
            for i in range(len(expressions)):
                self.expressions[f'Boolean expression {i}'] = expressions[i]
        elif isinstance(expressions, dict):
            self.expressions = expressions
        else:
            raise ValueError("Expressions must be list or dict.")

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
            if expr_out in self.intf_spec['traceable_outputs']:
                output_pin_num = self.intf_spec[
                    'traceable_outputs'][expr_out]
            elif expr_out in self.intf_spec['non_traceable_outputs']:
                output_pin_num = self.intf_spec[
                    'non_traceable_outputs'][expr_out]
            else:
                raise ValueError(f"Invalid output pin {expr_out}.")

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
                expr_in = f'({expr_in} & X{i})|({expr_in} & ~X{i})'
                input_pins_with_dontcares.append(f'X{i}')

            # Map to truth table
            p0, p1, p2, p3, p4 = map(exprvar, input_pins_with_dontcares)
            expr_p = expr_in

            # Use regular expression to match and replace whole word only
            for orig_name, p_name in zip(input_pins_with_dontcares,
                                         [f'p{i}' for i in range(5)]):
                expr_p = re.sub(r"\b{}\b".format(orig_name), p_name, expr_p)

            truth_table = expr2truthtable(eval(expr_p))

            # Parse truth table to send
            truth_list = str(truth_table).split("\n")
            truth_num = 0
            for i in range(32, 0, -1):
                truth_num = (truth_num << 1) + int(truth_list[i][-1])

            # Get current BG bit enables
            mailbox_addr = self.builder_controller.mmio.base_addr + \
                MAILBOX_OFFSET
            mailbox_regs = [Register(addr) for addr in range(
                mailbox_addr, mailbox_addr + 4 * 64, 4)]
            self.builder_controller.write_command(CMD_READ_CFG_DIRECTION)
            bit_enables = mailbox_regs[0][31:0]

            # Generate the input selects based on truth table and bit enables
            truth_table_inputs = [str(inp) for inp in truth_table.inputs]
            for i in range(5):
                lsb = i * 5
                msb = (i + 1) * 5 - 1
                if truth_table_inputs[i] in unique_input_pins:
                    if truth_table_inputs[i] in self.intf_spec[
                        'traceable_inputs'] and truth_table_inputs[i] \
                            in self.intf_spec['traceable_outputs']:
                        input_pin_ix = self.intf_spec[
                            'traceable_outputs'][truth_table_inputs[i]]
                    elif truth_table_inputs[i] in self.intf_spec[
                            'non_traceable_inputs']:
                        input_pin_ix = self.intf_spec[
                            'non_traceable_inputs'][truth_table_inputs[i]]
                    else:
                        raise ValueError(f"Invalid input pin "
                                         f"{truth_table_inputs[i]}.")
                else:
                    input_pin_ix = 0x1f
                mailbox_regs[output_pin_num * 2][msb:lsb] = input_pin_ix

            mailbox_regs[output_pin_num * 2 + 1][31:0] = truth_num
            mailbox_regs[48][31:0] = bit_enables
            mailbox_regs[48][output_pin_num] = 0

            mailbox_regs[49][31:0] = 0
            mailbox_regs[49][output_pin_num] = 1

            # Construct the command word
            self.builder_controller.write_command(CMD_CONFIG_CFG)

            # Setup waveform view - stimulus from inputs, analysis on outputs
            waveform_dict = {'signal': [
                ['stimulus'],
                {},
                ['analysis']],
                'foot': {'tick': 1},
                'head': {'tick': 1,
                         'text': f'{expr_label}: {expression}'}}

            # Append four inputs and one output to waveform view
            stimulus_traced = False
            for pin_name in unique_input_pins:
                if pin_name in self.intf_spec['traceable_inputs']:
                    stimulus_traced = True
                    waveform_dict['signal'][0].append({'name': pin_name,
                                                       'pin': pin_name})
            if not stimulus_traced:
                del (waveform_dict['signal'][0])

            if expr_out in self.intf_spec['traceable_outputs']:
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
            if self.builder_controller.pin_map[i] != 'UNUSED':
                raise ValueError(
                    f"Pin conflict: {self.builder_controller.pin_map[i]} "
                    f"already in use.")

        # Reserve pins only if there are no conflicts for any pin
        for i in self.output_pins:
            self.builder_controller.pin_map[i] = 'OUTPUT'
        for i in self.input_pins:
            self.builder_controller.pin_map[i] = 'INPUT'

        # Configure the trace analyzer and frequency
        if self.analyzer is not None:
            self.analyzer.setup(self.num_analyzer_samples,
                                frequency_mhz)
        else:
            self.builder_controller.clk.fclk1_mhz = frequency_mhz
        self.frequency_mhz = frequency_mhz

        # Update builder status
        self.builder_controller.check_status()

    def reset(self):
        """Reset the boolean builder.

        This method will bring the builder from any state to 
        'RESET' state.

        """
        # Stop the running builder if necessary
        self.stop()

        # Clear all the reserved pins
        for i in self.output_pins + self.input_pins:
            self.builder_controller.pin_map[i] = 'UNUSED'

        self.expressions.clear()
        self.output_pins.clear()
        self.input_pins.clear()
        self.waveforms.clear()
        self.frequency_mhz = 0

        # Send the reset command
        cmd_reset = CMD_RESET | CFG_ENGINE_BIT
        if self.analyzer is not None:
            cmd_reset |= TRACE_ENGINE_BIT
        self.builder_controller.write_command(cmd_reset)
        self.builder_controller.check_status()

    def connect(self):
        """Method to configure the IO switch.

        Usually this method should only be used internally. Users only need
        to use `run()` method.

        """
        # Gather which pins are being used
        ioswitch_pins = list()
        ioswitch_pins += [self.intf_spec['traceable_outputs'][input_pin]
                          for input_pin in self.input_pins
                          if input_pin in self.intf_spec['traceable_inputs']]
        ioswitch_pins += [self.intf_spec['traceable_outputs'][output_pin]
                          for output_pin in self.output_pins
                          if output_pin in self.intf_spec['traceable_outputs']]

        # Send list to Microblaze processor for handling
        self.builder_controller.config_ioswitch(ioswitch_pins,
                                                IOSWITCH_BG_SELECT)

    def disconnect(self):
        """Method to disconnect the IO switch.

        Usually this method should only be used internally. Users only need
        to use `stop()` method.

        """
        # Gather which pins are being used
        ioswitch_pins = list()
        ioswitch_pins += [self.intf_spec['traceable_outputs'][input_pin]
                          for input_pin in self.input_pins
                          if input_pin in self.intf_spec['traceable_inputs']]
        ioswitch_pins += [self.intf_spec['traceable_outputs'][output_pin]
                          for output_pin in self.output_pins
                          if output_pin in self.intf_spec['traceable_outputs']]

        # Send list to Microblaze processor for handling
        self.builder_controller.config_ioswitch(ioswitch_pins,
                                                IOSWITCH_DISCONNECT)

    def run(self):
        """Run the boolean builder.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to run the boolean 
        builder.

        """
        if self.builder_controller.status[self.__class__.__name__] == 'RESET':
            raise ValueError("Builder must be at least READY before RUNNING.")
        self.connect()
        cmd_run = CMD_RUN | CFG_ENGINE_BIT
        if self.analyzer is not None:
            cmd_run |= TRACE_ENGINE_BIT
        self.builder_controller.write_command(cmd_run)
        self.builder_controller.check_status()

    def step(self):
        """Step the boolean builder.

        The method will first collects the pins used and sends the list to 
        Microblaze for handling. Then it will start to step the boolean 
        builder.

        """
        if self.builder_controller.status[self.__class__.__name__] == 'RESET':
            raise ValueError("Builder must be at least READY before RUNNING.")
        self.connect()
        cmd_step = CMD_STEP | CFG_ENGINE_BIT
        if self.analyzer is not None:
            cmd_step |= TRACE_ENGINE_BIT
        self.builder_controller.write_command(cmd_step)
        self.builder_controller.check_status()

    def stop(self):
        """Stop the boolean builder.

        This method will stop the currently running boolean builder.

        """
        if self.builder_controller.status[
                self.__class__.__name__] == 'RUNNING':
            cmd_stop = CMD_STOP | CFG_ENGINE_BIT
            if self.analyzer is not None:
                cmd_stop |= TRACE_ENGINE_BIT
            self.builder_controller.write_command(cmd_stop)
            self.disconnect()
            self.builder_controller.check_status()

    def show_waveform(self):
        """Display the boolean logic builder in a Jupyter notebook.

        A wavedrom waveform is shown with all inputs and outputs displayed.

        """
        if self.analyzer is None:
            raise ValueError("Trace disabled, please enable and rerun.")

        analysis_group = self.analyzer.analyze()
        for expr_label in self.expressions.keys():
            self.waveforms[expr_label].update('stimulus', analysis_group)
            self.waveforms[expr_label].update('analysis', analysis_group)
            self.waveforms[expr_label].display()
