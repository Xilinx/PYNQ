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
from . import INTF_MICROBLAZE_BIN
from . import PYNQZ1_DIO_SPECIFICATION
from . import CMD_READ_CFG_DIRECTION
from . import MAILBOX_OFFSET
from . import CMD_CONFIG_CFG
from . import CMD_ARM_CFG
from . import IOSWITCH_BG_SELECT
from .intf import Intf
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
    intf : Intf
        The interface Microblaze object used by this class.
    expr : str
        The boolean expression in string format.
    intf_spec : dict
        The interface specification.
    waveform : Waveform
        The waveform object that can be used to display the waveform.
    input_pins : list
        A list of input pins, each input pin being a string.
    output_pin : str
        An output pin in the format of string.

    """
    def __init__(self, intf_microblaze, expr,
                 intf_spec=PYNQZ1_DIO_SPECIFICATION,
                 use_analyzer=True, num_analyzer_samples=16):
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
        intf_microblaze : Intf/dict
            The interface Microblaze object, or a dictionary storing 
            Microblaze information, such as the IP name and the reset name.
        expr : str
            The boolean expression to be configured.
        intf_spec : dict
            The interface specification.
        use_analyzer : bool
            Whether to attach an analyzer to the boolean builder.
        num_analyzer_samples : int
            Number of analyzer samples to capture.

        """
        if isinstance(intf_microblaze, Intf):
            self.intf = intf_microblaze
        elif isinstance(intf_microblaze, dict):
            self.intf = Intf(intf_microblaze)
        else:
            raise TypeError(
                "Parameter intf_microblaze has to be intf.Intf or dict.")

        self.expr = None
        self.intf_spec = intf_spec
        self.output_pin = None
        self.input_pins = None
        self.waveform = None

        if use_analyzer:
            self.analyzer = TraceAnalyzer(
                self.intf, num_samples=num_analyzer_samples,
                trace_spec=intf_spec)
        else:
            self.analyzer = None

        self.config(expr)

    def _config_ioswitch(self):
        """Configure the IO switch.

        Will only be used internally. The method collects the pins used and 
        sends the list _INTF for handling.

        """
        # gather which pins are being used
        ioswitch_pins = [self.intf_spec['traceable_outputs'][ins]
                         for ins in self.input_pins
                         if ins in self.intf_spec['traceable_outputs']]
        if self.output_pin in self.intf_spec['traceable_outputs']:
            ioswitch_pins.append(
                self.intf_spec['traceable_outputs'][self.output_pin])

        # send list to intf processor for handling
        self.intf.config_ioswitch(ioswitch_pins, IOSWITCH_BG_SELECT)

    def config(self, expr):
        """Configure the builder with new boolean expression.

        Implements boolean function at specified IO pins.

        This method is called during initialization, but can also be called 
        separately if users want to change the boolean expressions.

        Parameters
        ----------
        expr : str
            The new boolean expression.

        Returns
        -------
        None

        """
        if not isinstance(expr, str):
            raise TypeError("Boolean expression has to be a string.")

        if "=" not in expr:
            raise ValueError(
                "Boolean expression must have form OUTPUT_PIN = Expression")

        self.expr = expr

        # parse boolean expression into output & input string
        expr_out, expr_in = expr.split("=")
        expr_out = expr_out.strip()
        self.output_pin = expr_out
        if self.output_pin in self.intf_spec['traceable_outputs']:
            output_pin_num = self.intf_spec[
                'traceable_outputs'][self.output_pin]
        elif self.output_pin in self.intf_spec['non_traceable_outputs']:
            output_pin_num = self.intf_spec[
                'non_traceable_outputs'][self.output_pin]
        else:
            raise ValueError(f"Invalid output pin {expr_out}.")

        # parse the used pins preserving the order
        non_unique_inputs = re.sub("\W+", " ", expr_in).strip().split(' ')
        self.input_pins = list(OrderedDict.fromkeys(non_unique_inputs))
        if not 1 <= len(self.input_pins) <= 5:
            raise ValueError("Expect 1 - 5 inputs for each CFGLUT.")
        input_pins_with_dontcares = self.input_pins[:]

        # need 5 inputs to CFGLUT - any unspecified inputs will be don't cares
        for i in range(len(input_pins_with_dontcares), 5):
            expr_in = f'({expr_in} & X{i})|({expr_in} & ~X{i})'
            input_pins_with_dontcares.append(f'X{i}')

        # map to truth table
        p0, p1, p2, p3, p4 = map(exprvar, input_pins_with_dontcares)
        expr_p = expr_in

        # Use regular expression to match and replace whole word only
        for orig_name, p_name in zip(input_pins_with_dontcares,
                                     [f'p{i}' for i in range(5)]):
            expr_p = re.sub(r"\b{}\b".format(orig_name), p_name, expr_p)

        truth_table = expr2truthtable(eval(expr_p))

        # parse truth table to send
        truth_list = str(truth_table).split("\n")
        truth_num = 0
        for i in range(32, 0, -1):
            truth_num = (truth_num << 1) + int(truth_list[i][-1])

        # Set the IO Switch
        self._config_ioswitch()

        # Get current BG bit enables
        mailbox_addr = self.intf.mmio.base_addr + MAILBOX_OFFSET
        mailbox_regs = [Register(addr) for addr in range(
            mailbox_addr, mailbox_addr + 4 * 64, 4)]
        self.intf.write_command(CMD_READ_CFG_DIRECTION)
        bg_bitenables = mailbox_regs[0][31:0]

        # generate the input selects based on truth table and bit enables
        truth_table_inputs = [str(inp) for inp in truth_table.inputs]
        for i in range(5):
            lsb = i * 5
            msb = (i + 1) * 5 - 1
            if truth_table_inputs[i] in self.input_pins:
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
        mailbox_regs[48][31:0] = bg_bitenables
        mailbox_regs[48][output_pin_num] = 0

        mailbox_regs[49][31:0] = 0
        mailbox_regs[49][output_pin_num] = 1

        # construct the command word
        self.intf.write_command(CMD_CONFIG_CFG)

        # setup waveform view - stimulus from inputs, analysis on outputs
        waveform_dict = {'signal': [
            ['stimulus'],
            {},
            ['analysis']],
            'foot': {'tick': 1},
            'head': {'tick': 1,
                     'text': f'Boolean Logic Builder ({self.expr})'}}

        # Append four inputs and one output to waveform view
        stimulus_traced = False
        for name in self.input_pins:
            if name in self.intf_spec['traceable_inputs']:
                stimulus_traced = True
                waveform_dict['signal'][0].append({'name': name, 'pin': name})
        if not stimulus_traced:
            del (waveform_dict['signal'][0])

        if self.output_pin in self.intf_spec['traceable_outputs']:
            waveform_dict['signal'][-1].append({'name': self.output_pin,
                                                'pin': self.output_pin})
        else:
            del (waveform_dict['signal'][-1])

        self.waveform = Waveform(waveform_dict,
                                 stimulus_name='stimulus',
                                 analysis_name='analysis')

        # configure the trace analyzer
        if self.analyzer is not None:
            self.analyzer.config()

    def arm(self):
        """Arm the boolean builder.

        This method will prepare the boolean builder.

        """
        self.intf.write_command(CMD_ARM_CFG)

        if self.analyzer is not None:
            self.analyzer.arm()

    def is_armed(self):
        """Check if this builder's hardware is armed.

        Returns
        -------
        Bool
            True if the builder's hardware is armed.

        """
        return self.intf.armed_builders[CMD_ARM_CFG]

    def start(self):
        """Run the boolean generation.

        This method will start to run the boolean generation.

        """
        if not self.is_armed():
            self.arm()

        self.intf.start()

    def stop(self, free_buffer=True):
        """Stop the boolean generation.

        This method will stop the currently running boolean generation.

        Parameters
        ----------
        free_buffer : Bool
            The flag indicating whether or not to free the analyzer buffer.

        """
        self.intf.stop(free_buffer)

    def show_waveform(self):
        """Display the boolean logic generation in a Jupyter notebook.

        A wavedrom waveform is shown with all inputs and outputs displayed.

        """
        if self.analyzer is not None:
            analysis_group = self.analyzer.analyze()
            self.waveform.update('stimulus', analysis_group)
            self.waveform.update('analysis', analysis_group)
        else:
            raise ValueError("Trace disabled, please enable and rerun.")

        self.waveform.display()
