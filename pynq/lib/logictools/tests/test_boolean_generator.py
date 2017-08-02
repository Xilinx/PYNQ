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
from random import choice
from copy import deepcopy
import re
import pytest
from pynq import Overlay
from pynq.tests.util import user_answer_yes
from pynq.lib.logictools import LogicToolsController
from pynq.lib.logictools import BooleanGenerator
from pynq.lib.logictools.waveform import wave_to_bitstring
from pynq.lib.logictools import ARDUINO
from pynq.lib.logictools import PYNQZ1_LOGICTOOLS_SPECIFICATION


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    ol = Overlay('logictools.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest boolean generator?")
if flag1:
    mb_info = ARDUINO
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_state():
    """Test for the BooleanGenerator class.

    This test will test configurations when all 5 pins of a LUT are 
    specified. Users need to manually check the output.

    """
    ol.download()
    input('\nDisconnect all the pins. Hit enter after done ...')
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    first_6_pins = [k for k in list(pin_dict.keys())[:6]]
    out_pin = first_6_pins[5]
    in_pins = first_6_pins[0:5]
    or_expr = out_pin + '=' + ('|'.join(in_pins))

    bool_generator = BooleanGenerator(mb_info)
    assert bool_generator.status == 'RESET'

    bool_generator.trace()
    bool_generator.setup({'test_bool_state': or_expr})
    assert bool_generator.status == 'READY'

    bool_generator.run()
    assert bool_generator.status == 'RUNNING'

    print('Connect all of {} to GND ...'.format(in_pins))
    assert user_answer_yes("{} outputs logic low?".format(out_pin)), \
        "Boolean configurator fails to show logic low."
    print('Connect any of {} to VCC ...'.format(in_pins))
    assert user_answer_yes("{} outputs logic high?".format(out_pin)), \
        "Boolean configurator fails to show logic high."

    bool_generator.stop()
    assert bool_generator.status == 'READY'

    bool_generator.step()
    assert bool_generator.status == 'RUNNING'

    bool_generator.stop()
    assert bool_generator.status == 'READY'

    bool_generator.reset()
    assert bool_generator.status == 'RESET'

    del bool_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_no_trace():
    """Test for the BooleanGenerator class.

    This test will test whether users can show waveform when no trace analyzer
    is used. An exception should be raised.

    """
    ol.download()
    bool_generator = BooleanGenerator(mb_info)
    bool_generator.trace(use_analyzer=False)
    exception_raised = False
    try:
        bool_generator.show_waveform()
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception for show_waveform().'

    bool_generator.reset()
    del bool_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_multiple():
    """Test for the BooleanGenerator class.

    This test will test the configurations when only part of the 
    LUT pins are used. Multiple instances will be tested.
    This is an automatic test so no user interaction is needed.

    """
    ol.download()
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    first_10_pins = [k for k in list(pin_dict.keys())[:10]]
    in_pins = first_10_pins[0:5]
    out_pins = first_10_pins[5:10]
    test_expressions = list()
    operations = ['&', '|', '^']
    for i in range(5):
        operation = choice(operations)
        test_expressions.append(out_pins[i] + '=' +
                                (operation.join(sample(in_pins, i+1))))

    print('\nConnect randomly {} to VCC or GND.'.format(in_pins))
    input('Hit enter after done ...')

    bool_generator = BooleanGenerator(mb_info)
    bool_generator.trace()
    bool_generator.setup(expressions=test_expressions)
    bool_generator.run()

    for expr_label in bool_generator.expressions.keys():
        waveform = bool_generator.waveforms[expr_label]
        wavelanes_in = waveform.waveform_dict['signal'][0][1:]
        wavelanes_out = waveform.waveform_dict['signal'][-1][1:]
        expr = deepcopy(bool_generator.expressions[expr_label])
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
        assert eval(expr), "Boolean expression {} not evaluating " \
                           "correctly.".format(
            bool_generator.expressions[expr_label])

    bool_generator.stop()
    bool_generator.reset()
    del bool_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_step():
    """Test for the BooleanGenerator class.

    This test will test whether the `step()` method works correctly.
    Users will be asked to change input values during the test. The test
    scenario is also an extreme case where only 2 samples are captured.

    """
    ol.download()
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    first_10_pins = [k for k in list(pin_dict.keys())[:10]]
    in_pins = first_10_pins[0:5]
    out_pins = first_10_pins[5:10]
    test_expressions = list()
    operations = ['&', '|', '^']
    for i in range(5):
        operation = choice(operations)
        test_expressions.append(out_pins[i] + '=' +
                                (operation.join(sample(in_pins, i+1))))

    print('\nConnect randomly {} to VCC or GND.'.format(in_pins))
    input('Hit enter after done ...')

    bool_generator = BooleanGenerator(mb_info)
    bool_generator.trace(num_analyzer_samples=2)
    bool_generator.setup(expressions=test_expressions)

    for i in range(2):
        print('Change some of the connections from {}.'.format(in_pins))
        input('Hit enter after done ...')
        bool_generator.step()

        for expr_label in bool_generator.expressions.keys():
            waveform = bool_generator.waveforms[expr_label]
            wavelanes_in = waveform.waveform_dict['signal'][0][1:]
            wavelanes_out = waveform.waveform_dict['signal'][-1][1:]
            expr = deepcopy(bool_generator.expressions[expr_label])
            for wavelane in wavelanes_in:
                wavelane_bitstring = wave_to_bitstring(wavelane['wave'])
                str_replace = wavelane_bitstring[i]
                expr = re.sub(r"\b{}\b".format(wavelane['name']),
                              str_replace, expr)

            wavelane = wavelanes_out[0]
            wavelane_bitstring = wave_to_bitstring(wavelane['wave'])
            str_replace = wavelane_bitstring[i]
            expr = re.sub(r"\b{}\b".format(wavelane['name']),
                          str_replace, expr)
            expr = expr.replace('=', '==')
            assert eval(expr), "Boolean expression {} not evaluating " \
                               "correctly in step {}.".format(
                bool_generator.expressions[expr_label], i)

    bool_generator.stop()
    bool_generator.reset()
    del bool_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_zero_inputs():
    """Test for the BooleanGenerator class.

    This test will test whether 0-input expressions are accepted.

    """
    ol.download()
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    first_1_pin = list(pin_dict.keys())[0]
    expr_no_input = first_1_pin + '='

    bool_generator = BooleanGenerator(mb_info)
    exception_raised = False
    try:
        bool_generator.trace()
        bool_generator.setup(expressions=[expr_no_input])
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception if function has 0 input.'

    bool_generator.reset()
    del bool_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_six_inputs():
    """Test for the BooleanGenerator class.

    This test will test whether 6-input expressions are accepted.

    """
    ol.download()
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    first_1_pin = list(pin_dict.keys())[0]
    next_6_pins = [k for k in list(pin_dict.keys())[1:7]]
    expr_6_inputs = first_1_pin + '=' + ('&'.join(next_6_pins))

    bool_generator = BooleanGenerator(mb_info)
    exception_raised = False
    try:
        bool_generator.trace()
        bool_generator.setup(expressions=[expr_6_inputs])
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception if function has 6 inputs.'

    bool_generator.reset()
    del bool_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_zero_outputs():
    """Test for the BooleanGenerator class.

    This test will test whether 0-output expressions are accepted.

    """
    ol.download()
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    first_1_pin = list(pin_dict.keys())[0]
    expr_no_rhs = first_1_pin

    bool_generator = BooleanGenerator(mb_info)
    exception_raised = False
    try:
        bool_generator.trace()
        bool_generator.setup(expr_no_rhs)
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception if function has no RHS.'

    bool_generator.reset()
    del bool_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_bool_max_num_expr():
    """Test for the BooleanGenerator class.

    This test will implement a maximum number of boolean generators, 
    each having 1 input. For example, PYNQ-Z1 has 20 pins for Arduino header, 
    so 19 boolean generators will be implemented, each having 1 output 
    assigned to 1 pin. All the generators share the same input pin.

    """
    ol.download()
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    interface_width = PYNQZ1_LOGICTOOLS_SPECIFICATION['interface_width']
    all_pins = [k for k in list(pin_dict.keys())[:interface_width]]
    num_expressions = interface_width - 1
    in_pin = all_pins[0]
    out_pins = all_pins[1:]
    test_expressions = list()
    for i in range(num_expressions):
        test_expressions.append(out_pins[i] + '=' + in_pin)

    print("")
    bool_generator = BooleanGenerator(mb_info)
    for voltage in ['VCC', 'GND']:
        print('Disconnect all the pins. Connect only {} to {}.'.format(
            in_pin, voltage))
        input('Press enter when done ...')

        bool_generator.trace()
        bool_generator.setup(expressions=test_expressions)
        bool_generator.run()

        for expr_label in bool_generator.expressions.keys():
            waveform = bool_generator.waveforms[expr_label]
            wavelanes_in = waveform.waveform_dict['signal'][0][1:]
            wavelanes_out = waveform.waveform_dict['signal'][-1][1:]
            expr = deepcopy(bool_generator.expressions[expr_label])

            wavelane = wavelanes_in[0]
            wavelane_bitstring = wave_to_bitstring(wavelane['wave'])
            str_replace = wavelane_bitstring[0]
            expr = re.sub(r"\b{}\b".format(wavelane['name']),
                          str_replace, expr)

            wavelane = wavelanes_out[0]
            wavelane_bitstring = wave_to_bitstring(wavelane['wave'])
            str_replace = wavelane_bitstring[0]
            expr = re.sub(r"\b{}\b".format(wavelane['name']),
                          str_replace, expr)

            expr = expr.replace('=', '==')
            assert eval(expr), "Boolean expression {} not evaluating " \
                               "correctly.".format(
                bool_generator.expressions[expr_label])

        bool_generator.stop()
        bool_generator.reset()

    del bool_generator
