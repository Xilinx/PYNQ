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
from math import ceil
from time import sleep
from random import randint
from random import choice
from copy import deepcopy
import numpy as np
import pytest
from pynq import Overlay
from pynq.tests.util import user_answer_yes
from pynq.lib.logictools.waveform import bitstring_to_int
from pynq.lib.logictools.waveform import wave_to_bitstring
from pynq.lib.logictools.waveform import bitstring_to_wave
from pynq.lib.logictools import FSMGenerator
from pynq.lib.logictools import PatternGenerator
from pynq.lib.logictools import BooleanGenerator
from pynq.lib.logictools import LogicToolsController
from pynq.lib.logictools import ARDUINO
from pynq.lib.logictools import PYNQZ1_LOGICTOOLS_SPECIFICATION
from pynq.lib.logictools import MAX_NUM_PATTERN_SAMPLES
from pynq.lib.logictools import FSM_MIN_STATE_BITS
from pynq.lib.logictools import FSM_MAX_STATE_BITS
from pynq.lib.logictools import FSM_MIN_NUM_STATES
from pynq.lib.logictools import FSM_MAX_NUM_STATES
from pynq.lib.logictools import FSM_MIN_INPUT_BITS
from pynq.lib.logictools import FSM_MAX_INPUT_BITS
from pynq.lib.logictools import FSM_MAX_STATE_INPUT_BITS
from pynq.lib.logictools import FSM_MAX_OUTPUT_BITS


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    ol = Overlay('logictools.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest all the generators together?")
if flag1:
    mb_info = ARDUINO
flag = flag0 and flag1


pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
interface_width = PYNQZ1_LOGICTOOLS_SPECIFICATION['interface_width']
all_pins = [k for k in list(pin_dict.keys())[:interface_width]]

# FSM spec
out, rst, direction = all_pins[0:3]
fsm_spec = {'inputs': [('rst', rst), ('direction', direction)],
            'outputs': [('test', out)],
            'states': ['S0', 'S1', 'S2', 'S3'],
            'transitions': [['00', 'S0', 'S1', '0'],
                            ['01', 'S0', 'S3', '0'],
                            ['00', 'S1', 'S2', '0'],
                            ['01', 'S1', 'S0', '0'],
                            ['00', 'S2', 'S3', '0'],
                            ['01', 'S2', 'S1', '0'],
                            ['00', 'S3', 'S0', '1'],
                            ['01', 'S3', 'S2', '1'],
                            ['1-', '*', 'S0', '']]}
output_pattern = [0, 1, 0, 0]

# Pattern spec
loopback_max_samples = {'signal': [
                    ['stimulus'],
                    {},
                    ['analysis']],
            'foot': {'tock': 1},
            'head': {'text': 'Loopback Test'}}
loopback_64_samples = deepcopy(loopback_max_samples)
for i in range(3, 7):
    stimulus_lane_max_samples = dict()
    analysis_lane_max_samples = dict()
    stimulus_lane_max_samples['name'] = 'clk{}'.format(i)
    analysis_lane_max_samples['name'] = 'clk{}'.format(i)
    stimulus_lane_max_samples['pin'] = all_pins[i]
    analysis_lane_max_samples['pin'] = all_pins[i]
    loopback_max_samples['signal'][-1].append(analysis_lane_max_samples)
    bitstring = ''.join(['{}'.format(randint(0, 1))
                         for _ in range(MAX_NUM_PATTERN_SAMPLES)])
    stimulus_lane_max_samples['wave'] = bitstring_to_wave(bitstring)
    loopback_max_samples['signal'][0].append(stimulus_lane_max_samples)
for i in range(3, 7):
    stimulus_lane_64_samples = dict()
    analysis_lane_64_samples = dict()
    stimulus_lane_64_samples['name'] = 'clk{}'.format(i)
    analysis_lane_64_samples['name'] = 'clk{}'.format(i)
    stimulus_lane_64_samples['pin'] = all_pins[i]
    analysis_lane_64_samples['pin'] = all_pins[i]
    loopback_64_samples['signal'][-1].append(analysis_lane_64_samples)
    if i == 3:
        bitstring = '01' * 32
    elif i == 4:
        bitstring = '0011' * 16
    elif i == 5:
        bitstring = ('0' * 4 + '1' * 4) * 8
    else:
        bitstring = ('0' * 8 + '1' * 8) * 4
    stimulus_lane_64_samples['wave'] = bitstring_to_wave(bitstring)
    loopback_64_samples['signal'][0].append(stimulus_lane_64_samples)

# Boolean spec
in_pins = all_pins[7:12]
test_expressions = list()
test_expressions.append(all_pins[12] + '=' + ('&'.join(in_pins)))
test_expressions.append(
    all_pins[13] + '=' +
    list(PYNQZ1_LOGICTOOLS_SPECIFICATION['non_traceable_inputs'].keys())[0])
test_expressions.append(
    list(PYNQZ1_LOGICTOOLS_SPECIFICATION['non_traceable_outputs'].keys())[0] +
    '=' + ('|'.join(in_pins)))


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_all_generators_state():
    """Test all the generator classes implemented in this overlay.

    In this test, the boolean generators, pattern generators, and 
    FSM generators are all instantiated. Their states are checked during 
    the test. A maximum number of pattern samples are tested.

    """
    ol.download()
    print("\nConnect {} to GND, and {} to VCC.".format(rst, direction))
    input("Hit enter after done ...")
    print('Connect randomly {} to VCC or GND.'.format(in_pins))
    input('Hit enter after done ...')

    fsm_generator = FSMGenerator(mb_info)
    assert fsm_generator.status == 'RESET'
    fsm_generator.trace(use_analyzer=False)
    fsm_generator.setup(fsm_spec, frequency_mhz=10)
    assert fsm_generator.status == 'READY'

    pattern_generator = PatternGenerator(mb_info)
    assert pattern_generator.status == 'RESET'
    pattern_generator.trace(use_analyzer=False)
    pattern_generator.setup(loopback_max_samples,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis',
                            frequency_mhz=10)
    assert pattern_generator.status == 'READY'

    boolean_generator = BooleanGenerator(mb_info)
    assert boolean_generator.status == 'RESET'
    boolean_generator.trace(use_analyzer=False)
    boolean_generator.setup(expressions=test_expressions,
                            frequency_mhz=10)
    assert boolean_generator.status == 'READY'

    for generator in [fsm_generator, pattern_generator, boolean_generator]:
        generator.step()
        assert generator.status == 'RUNNING'
        generator.stop()
        assert fsm_generator.status == 'READY'
        assert pattern_generator.status == 'READY'
        assert boolean_generator.status == 'READY'
        generator.run()
        assert generator.status == 'RUNNING'
        generator.stop()
        assert fsm_generator.status == 'READY'
        assert pattern_generator.status == 'READY'
        assert boolean_generator.status == 'READY'

    for generator in [fsm_generator, pattern_generator, boolean_generator]:
        generator.reset()
        assert generator.status == 'RESET'

    del fsm_generator, pattern_generator, boolean_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_all_generators_data():
    """Test all the generator classes implemented in this overlay.

    In this test, the boolean generators, pattern generators, and 
    FSM generators are tested together by a single call to the controller. 
    The input and output patterns are checked during the test.

    """
    ol.download()
    logictools_controller = LogicToolsController(
        mb_info, 'PYNQZ1_LOGICTOOLS_SPECIFICATION')
    for generator_name in logictools_controller.status:
        assert logictools_controller.status[generator_name] == 'RESET'

    print("\nConnect {} to GND, and {} to VCC.".format(rst, direction))
    input("Hit enter after done ...")
    print('Connect randomly {} to VCC or GND.'.format(in_pins))
    input("Hit enter after done ...")

    num_samples = MAX_NUM_PATTERN_SAMPLES
    fsm_generator = FSMGenerator(mb_info)
    fsm_generator.trace(num_analyzer_samples=num_samples)
    fsm_generator.setup(fsm_spec,
                        frequency_mhz=100)
    pattern_generator = PatternGenerator(mb_info)
    pattern_generator.trace(num_analyzer_samples=num_samples)
    pattern_generator.setup(loopback_max_samples,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis',
                            frequency_mhz=100)
    boolean_generator = BooleanGenerator(mb_info)
    boolean_generator.trace(num_analyzer_samples=num_samples)
    boolean_generator.setup(expressions=test_expressions,
                            frequency_mhz=100)

    logictools_controller.run([fsm_generator,
                               pattern_generator,
                               boolean_generator])
    for generator_name in logictools_controller.status:
        if generator_name != 'TraceAnalyzer':
            assert logictools_controller.status[generator_name] == 'RUNNING'

    check_boolean_data(boolean_generator)
    check_pattern_data(pattern_generator, num_samples)
    check_fsm_data(fsm_generator, num_samples)

    logictools_controller.stop([fsm_generator,
                                pattern_generator,
                                boolean_generator])
    for generator_name in logictools_controller.status:
        assert logictools_controller.status[generator_name] == 'READY'

    logictools_controller.reset([fsm_generator,
                                pattern_generator,
                                boolean_generator])
    for generator_name in logictools_controller.status:
        assert logictools_controller.status[generator_name] == 'RESET'
    del fsm_generator, pattern_generator, boolean_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_all_generators_step():
    """Test all the generator classes implemented in this overlay.

    In this test, the boolean generators, pattern generators, and 
    FSM generators are tested together by calling the `step()` method. By
    stepping for enough number of samples, the waveform should look identical
    to the results received by calling `run()` directly.

    """
    ol.download()
    logictools_controller = LogicToolsController(
        mb_info, 'PYNQZ1_LOGICTOOLS_SPECIFICATION')
    for generator_name in logictools_controller.status:
        assert logictools_controller.status[generator_name] == 'RESET'

    print("\nConnect {} to GND, and {} to VCC.".format(rst, direction))
    input("Hit enter after done ...")
    print('Connect randomly {} to VCC or GND.'.format(in_pins))
    input("Hit enter after done ...")

    num_samples = 64
    fsm_generator = FSMGenerator(mb_info)
    fsm_generator.trace(num_analyzer_samples=num_samples)
    fsm_generator.setup(fsm_spec,
                        frequency_mhz=10)
    pattern_generator = PatternGenerator(mb_info)
    pattern_generator.trace(num_analyzer_samples=num_samples)
    pattern_generator.setup(loopback_64_samples,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis',
                            frequency_mhz=10)
    boolean_generator = BooleanGenerator(mb_info)
    boolean_generator.trace(num_analyzer_samples=num_samples)
    boolean_generator.setup(expressions=test_expressions,
                            frequency_mhz=10)

    for _ in range(num_samples):
        logictools_controller.step([fsm_generator,
                                    pattern_generator,
                                    boolean_generator])
    for generator_name in logictools_controller.status:
        if generator_name != 'TraceAnalyzer':
            assert logictools_controller.status[generator_name] == 'RUNNING'

    check_boolean_data(boolean_generator)
    check_pattern_data(pattern_generator, num_samples)
    check_fsm_data(fsm_generator, num_samples)

    logictools_controller.stop([fsm_generator,
                                pattern_generator,
                                boolean_generator])
    for generator_name in logictools_controller.status:
        assert logictools_controller.status[generator_name] == 'READY'

    logictools_controller.reset([fsm_generator,
                                pattern_generator,
                                boolean_generator])
    for generator_name in logictools_controller.status:
        assert logictools_controller.status[generator_name] == 'RESET'
    del fsm_generator, pattern_generator, boolean_generator


def check_fsm_data(fsm_generator, num_samples):
    """Check whether the FSM generator returns correct data pattern.

    Parameters
    ----------
    fsm_generator : FSMGenerator
        The FSM generator after a successful run.
    num_samples : int
        The number of samples to test.

    """
    test_string = ''
    for wavegroup in fsm_generator.waveform.waveform_dict['signal']:
        if wavegroup and wavegroup[0] == 'analysis':
            for wavelane in wavegroup[1:]:
                if wavelane['name'] == 'test':
                    test_string = wavelane['wave']
    test_array = np.array(bitstring_to_int(wave_to_bitstring(test_string)))

    golden_test_array = np.tile(np.array(output_pattern),
                                ceil(num_samples / 4))
    assert np.array_equal(test_array,
                          golden_test_array[:num_samples]), \
        'Analysis not matching the generated pattern in FSM.'


def check_pattern_data(pattern_generator, num_samples):
    """Check whether the pattern generator returns correct data pattern.

    Parameters
    ----------
    pattern_generator : PatternGenerator
        The pattern generator after a successful run.
    num_samples : int
        The number of samples to test.

    """
    if num_samples == MAX_NUM_PATTERN_SAMPLES:
        data_pattern_sent = loopback_max_samples
    else:
        data_pattern_sent = loopback_64_samples
    loopback_recv = pattern_generator.waveform.waveform_dict
    stimulus_sent = stimulus_recv = analysis_recv = list()
    for wavelane_group in data_pattern_sent['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            stimulus_sent = wavelane_group[1:]

    for wavelane_group in loopback_recv['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            stimulus_recv = wavelane_group[1:]
        elif wavelane_group and wavelane_group[0] == 'analysis':
            analysis_recv = wavelane_group[1:]

    assert stimulus_sent == stimulus_recv, \
        'Stimulus not equal in generated and captured patterns.'
    assert stimulus_recv == analysis_recv, \
        'Stimulus not equal to analysis in captured patterns.'


def check_boolean_data(boolean_generator):
    """Check whether the boolean generator returns correct data pattern.

    Parameters
    ----------
    boolean_generator : BooleanGenerator
        The boolean generator after a successful run.

    """
    expression_label = 'Boolean expression 0'
    wavelanes_in = boolean_generator.waveforms[
                       expression_label].waveform_dict['signal'][0][1:]
    wavelanes_out = boolean_generator.waveforms[
                       expression_label].waveform_dict['signal'][-1][1:]
    expr = deepcopy(test_expressions[0])
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
    assert eval(expr), "Boolean expression {} fails.".format(
        test_expressions[0])
