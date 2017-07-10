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


from random import sample
from copy import deepcopy
import re
import pytest
from pynq import Overlay
from pynq.tests.util import user_answer_yes
from pynq.lib.intf import Intf
from pynq.lib.intf import BooleanBuilder
from pynq.lib.intf import ARDUINO
from pynq.lib.intf import PYNQZ1_DIO_SPECIFICATION


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    _ = Overlay('interface.bit')
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest boolean builder?")
if flag1:
    if_id = ARDUINO
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need interface overlay to run")
def test_bool_builder():
    """Test for the BooleanBuilder class.

    The 1st test will test configurations when all 5 pins of a LUT are 
    specified. Users need to manually check the output.

    The 2nd test will test the configurations when only part of the 
    LUT pins are used. Multiple instances will be tested.
    This is an automatic test so no user interaction is needed.

    The 3rd test will test whether 0-input or 6-input expressions are 
    accepted.

    The 4th test will implement a maximum number of boolean builders, 
    each having 1 input. For example, PYNQ-Z1 has 20 pins for Arduino header, 
    so 19 boolean builders will be implemented, each having 1 output assigned 
    to 1 pin. All the builders share the same input pin.

    """
    ol = Overlay('interface.bit')
    ol.download()

    # Test 1: manual test
    input(f'\nDisconnect all the pins. Hit enter after done ...')
    pin_dict = PYNQZ1_DIO_SPECIFICATION['traceable_outputs']
    first_6_pins = [k for k in list(pin_dict.keys())[:6]]
    out_pin = first_6_pins[5]
    in_pins = first_6_pins[0:5]
    or_expr = out_pin + '=' + ('|'.join(in_pins))
    bool_builder = BooleanBuilder(if_id, expr=or_expr)
    bool_builder.arm()
    bool_builder.start()
    bool_builder.show_waveform()
    print(f'Connect all of {in_pins} to GND ...')
    assert user_answer_yes(f"{out_pin} outputs logic low?"), \
        "Boolean configurator fails to show logic low."
    print(f'Connect any of {in_pins} to VCC ...')
    assert user_answer_yes(f"{out_pin} outputs logic high?"), \
        "Boolean configurator fails to show logic high."

    bool_builder0 = BooleanBuilder(if_id, expr=or_expr, use_analyzer=False)
    exception_raised = False
    try:
        bool_builder0.show_waveform()
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception for show_waveform().'

    bool_builder.stop()
    del bool_builder, bool_builder0

    # Test 2: automatic test
    pin_dict = PYNQZ1_DIO_SPECIFICATION['traceable_outputs']
    microblaze_intf = Intf(if_id)
    first_10_pins = [k for k in list(pin_dict.keys())[:10]]
    in_pins = first_10_pins[0:5]
    out_pins = first_10_pins[5:10]
    fx = list()
    for i in range(5):
        fx.append(out_pins[i] + '=' + ('&'.join(sample(in_pins, i+1))))

    print(f'Connect randomly {in_pins} to VCC or GND.')
    input(f'Hit enter after done ...')
    bgs = [BooleanBuilder(microblaze_intf, expr=fx[i]) for i in range(5)]

    for i in range(5):
        bgs[i].arm()
        bgs[i].start()
        bgs[i].show_waveform()
        wavelanes_in = bgs[i].waveform.waveform_dict['signal'][0][1:]
        wavelanes_out = bgs[i].waveform.waveform_dict['signal'][-1][1:]
        expr = deepcopy(fx[i])
        for wavelane in wavelanes_in:
            if 'h' == wavelane['wave'][0]:
                str_replace = '1'
            elif 'l' == wavelane['wave'][0]:
                str_replace = '0'
            else:
                raise ValueError("Unrecognizable pattern captured.")
            expr = re.sub(r"\b{}\b".format(wavelane['name']),
                          str_replace, expr)

        wavelane = wavelanes_out[0]
        if 'h' == wavelane['wave'][0]:
            str_replace = '1'
        elif 'l' == wavelane['wave'][0]:
            str_replace = '0'
        else:
            raise ValueError("Unrecognizable pattern captured.")
        expr = re.sub(r"\b{}\b".format(wavelane['name']),
                      str_replace, expr)
        expr = expr.replace('=', '==')
        assert eval(expr), f"Boolean builder fails for {fx[i]}."

    for bg in bgs:
        bg.stop()
        bg.intf.reset_buffers()
        del bg

    # Test 3: 0 or 6-input test
    pin_dict = PYNQZ1_DIO_SPECIFICATION['traceable_outputs']
    first_1_pin = list(pin_dict.keys())[0]
    next_6_pins = [k for k in list(pin_dict.keys())[1:7]]
    expr_no_rhs = first_1_pin
    expr_no_input = first_1_pin + '='
    expr_6_inputs = first_1_pin + '=' + ('&'.join(next_6_pins))
    bool_builder = BooleanBuilder(if_id, expr=or_expr, use_analyzer=False)

    exception_raised = False
    try:
        bool_builder.config(expr_no_rhs)
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception if function has no RHS.'

    exception_raised = False
    try:
        bool_builder.config(expr_no_input)
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception if function has 0 input.'

    exception_raised = False
    try:
        bool_builder.config(expr_6_inputs)
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception if function has 6 inputs.'

    bool_builder.intf.reset_buffers()
    del bool_builder

    # Test 4: maximum number of builders
    pin_dict = PYNQZ1_DIO_SPECIFICATION['traceable_outputs']
    interface_width = PYNQZ1_DIO_SPECIFICATION['interface_width']
    all_pins = [k for k in list(pin_dict.keys())[:interface_width]]
    num_bgs = interface_width - 1
    in_pin = all_pins[0]
    out_pins = all_pins[1:]
    fx = list()
    for i in range(num_bgs):
        fx.append(out_pins[i] + '=' + in_pin)

    microblaze_intf = Intf(if_id)
    bgs = [BooleanBuilder(microblaze_intf, expr=expr) for expr in fx]
    for voltage in ['VCC', 'GND']:
        print(f'Disconnect all the pins. Connect only {in_pin} to {voltage}.')
        input(f'Press enter when done ...')
        for i in range(num_bgs):
            bgs[i].arm()
        microblaze_intf.start()
        for i in range(num_bgs):
            bgs[i].show_waveform()

            wavelanes_in = bgs[i].waveform.waveform_dict['signal'][0][1:]
            wavelanes_out = bgs[i].waveform.waveform_dict['signal'][-1][1:]
            expr = deepcopy(fx[i])

            wavelane = wavelanes_in[0]
            if 'h' == wavelane['wave'][0]:
                str_replace = '1'
            elif 'l' == wavelane['wave'][0]:
                str_replace = '0'
            else:
                raise ValueError("Unrecognizable pattern captured.")
            expr = re.sub(r"\b{}\b".format(wavelane['name']),
                          str_replace, expr)

            wavelane = wavelanes_out[0]
            if 'h' == wavelane['wave'][0]:
                str_replace = '1'
            elif 'l' == wavelane['wave'][0]:
                str_replace = '0'
            else:
                raise ValueError("Unrecognizable pattern captured.")
            expr = re.sub(r"\b{}\b".format(wavelane['name']),
                          str_replace, expr)

            expr = expr.replace('=', '==')
            assert eval(expr), f"Boolean builder fails for {fx[i]}."

    for bg in bgs:
        bg.stop()
        del bg
    microblaze_intf.reset_buffers()
    ol.reset()
