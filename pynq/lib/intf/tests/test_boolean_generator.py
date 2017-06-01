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
from pynq.intf import request_intf
from pynq.intf import BooleanGenerator
from pynq.intf.intf_const import PYNQZ1_DIO_SPECIFICATION


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


ol = Overlay('interface.bit')


@pytest.mark.run(order=45)
def test_bool_func_1():
    """Test for the BooleanGenerator class.

    The first test will test configurations when all 5 pins of a LUT are 
    specified. Users need to manually check the output.

    """
    if_id = 3
    pin_dict = PYNQZ1_DIO_SPECIFICATION['output_pin_map']
    first_6_pins = [k for k in list(pin_dict.keys())[:6]]
    out_pin = first_6_pins[5]
    in_pins = first_6_pins[0:5]
    or_expr = out_pin + '=' + ('|'.join(in_pins))
    bool_generator = BooleanGenerator(if_id)
    bool_generator.config(or_expr)
    bool_generator.arm()
    bool_generator.run()
    bool_generator.display()
    print(f'\nConnect all of {in_pins} to GND ...')
    assert user_answer_yes(f"{out_pin} outputs logic low?"), \
        "Boolean configurator fails to show logic low."
    print(f'Connect any of {in_pins} to 3V3 ...')
    assert user_answer_yes(f"{out_pin} outputs logic high?"), \
        "Boolean configurator fails to show logic high."

    bool_generator0 = BooleanGenerator(if_id, use_analyzer=False)
    exception_raised = False
    try:
        bool_generator0.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception for display().'

    bool_generator.stop()
    bool_generator.analyzer.reset()
    del bool_generator, bool_generator0


@pytest.mark.run(order=46)
def test_bool_func_2():
    """Test for the BooleanGenerator class.

    The second test will test the configurations when only part of the 
    LUT pins are used. Multiple instances will be tested.
    
    For simplicity, pins D0 - D4 will be used as input pins, while D5 - D9
    will be selected as output pins.
    
    This is an automatic test so no user interaction is needed.

    """
    if_id = 3
    pin_dict = PYNQZ1_DIO_SPECIFICATION['output_pin_map']
    microblaze_intf = request_intf(if_id)
    first_10_pins = [k for k in list(pin_dict.keys())[:10]]
    in_pins = first_10_pins[0:5]
    out_pins = first_10_pins[5:10]
    fx = list()
    for i in range(5):
        fx.append(out_pins[i] + '=' + ('&'.join(sample(in_pins,i+1))))

    print(f'\nConnect randomly {in_pins} to 3V3 or GND.')
    bgs = [BooleanGenerator(microblaze_intf) for _ in range(5)]

    # Arm all the boolean generator and run them
    for i in range(5):
        bgs[i].config(fx[i])
        bgs[i].arm()
        bgs[i].run()
        bgs[i].display()
        bgs[i].stop()
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
        assert eval(expr), f"Boolean generator fails for {fx[i]}."

    for bg in bgs:
        bg.intf.reset_buffers()
        del bg
    ol.reset()

