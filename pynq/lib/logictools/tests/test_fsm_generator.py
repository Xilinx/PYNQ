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
#   3.  Neither the name of the copyright holder no r the names of its
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


from random import randint
from math import ceil
import numpy as np
import pytest
from pynq import Overlay
from pynq.tests.util import user_answer_yes
from pynq.lib.logictools.waveform import bitstring_to_int
from pynq.lib.logictools.waveform import wave_to_bitstring
from pynq.lib.logictools import FSMGenerator
from pynq.lib.logictools import ARDUINO
from pynq.lib.logictools import PYNQZ1_LOGICTOOLS_SPECIFICATION
from pynq.lib.logictools import MAX_NUM_TRACE_SAMPLES
from pynq.lib.logictools import FSM_MIN_NUM_STATES
from pynq.lib.logictools import FSM_MAX_NUM_STATES
from pynq.lib.logictools import FSM_MAX_INPUT_BITS
from pynq.lib.logictools import FSM_MAX_STATE_INPUT_BITS


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    ol = Overlay('logictools.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest Finite State Machine (FSM) generator?")
if flag1:
    mb_info = ARDUINO
flag = flag0 and flag1


pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
interface_width = PYNQZ1_LOGICTOOLS_SPECIFICATION['interface_width']


def build_fsm_spec_4_state(direction_logic_value):
    """Build an FSM spec with 4 states.

    The FSM built has 2 inputs, 1 output, and 4 states. It acts like a 
    2-bit counter, where the output goes to high only if the FSM is in the 
    final state.

    When the direction pin is low, the counter counts up; if it is high, the
    counter counts down.

    Parameters
    ----------
    direction_logic_value : int
        The logic value of the direction pin.
    Returns
    -------
    dict
        The FSM spec that can be consumed by the FSM generator.
    list
        The output pattern corresponding to the direction value.
    list
        The state bit0 pattern corresponding to the direction value.
    list
        The state bit1 pattern corresponding to the direction value.

    """
    out, rst, direction = list(pin_dict.keys())[0:3]
    fsm_spec_4_state = {'inputs': [('rst', rst), ('direction', direction)],
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
    if not direction_logic_value:
        output_pattern = [0, 0, 0, 1]
        state_bit0_pattern = [0, 1, 0, 1]
        state_bit1_pattern = [0, 0, 1, 1]
    else:
        output_pattern = [0, 1, 0, 0]
        state_bit0_pattern = [0, 1, 0, 1]
        state_bit1_pattern = [0, 1, 1, 0]
    return fsm_spec_4_state, \
        output_pattern, state_bit0_pattern, state_bit1_pattern


def build_fsm_spec_random(num_states):
    """Build an FSM spec with the specified number of states.

    The FSM spec exploits only single input and single output. As a side 
    product, a list of output patterns are also returned.

    Parameters
    ----------
    num_states : int
        The number of states of the FSM.

    Returns
    -------
    dict
        The FSM spec that can be consumed by the FSM generator.
    list
        The output patterns associated with this FSM spec.

    """
    input_pin, output_pin = list(pin_dict.keys())[0:2]
    if num_states == 1:
        return {'inputs': [('rst', input_pin)],
                'outputs': [('test', output_pin)],
                'states': ['S0'],
                'transitions': [['1', '*', 'S0', '']]}, None
    else:
        fsm_spec_state = {'inputs': [('rst', input_pin)],
                          'outputs': [('test', output_pin)],
                          'states': [],
                          'transitions': [['1', '*', 'S0', '']]}
        output_pattern_list = list()
        for i in range(num_states):
            current_state = 'S{}'.format(i)
            next_state = 'S{}'.format((i+1) % num_states)
            fsm_spec_state['states'] += [current_state]
            output_pattern = '{}'.format(randint(0, 1))
            transition = ['0', current_state, next_state, output_pattern]
            fsm_spec_state['transitions'] += [transition]
            output_pattern_list.append(int(output_pattern))
        return fsm_spec_state, output_pattern_list


def build_fsm_spec_max_in_out():
    """Build an FSM spec using a maximum number of inputs and outputs.

    The returned FSM spec has a maximum number of inputs and 
    outputs. At the same time, the largest available number of 
    states will be implemented. For example, on PYNQ-Z1, if 
    FSM_MAX_INPUT_BITS = 8, and FSM_MAX_STATE_INPUT_BITS = 13, we will 
    implement 2**(13-8)-1 = 31 states. This is the largest number of states 
    available for this setup, since there is always 1 dummy state that has
    to be reserved.

    Returns
    -------
    dict
        The FSM spec that can be consumed by the FSM generator.
    list
        The output patterns associated with this FSM spec.

    """
    input_pins = list(pin_dict.keys())[:FSM_MAX_INPUT_BITS]
    output_pins = list(pin_dict.keys())[FSM_MAX_INPUT_BITS:interface_width]
    fsm_spec_inout = {'inputs': [],
                      'outputs': [],
                      'states': [],
                      'transitions': [['1' * len(input_pins), '*', 'S0', '']]}
    test_lanes = [[] for _ in range(len(output_pins))]
    num_states = 2 ** (FSM_MAX_STATE_INPUT_BITS - FSM_MAX_INPUT_BITS) - 1
    for i in range(len(input_pins)):
        fsm_spec_inout['inputs'].append(('input{}'.format(i),
                                         input_pins[i]))
    for i in range(len(output_pins)):
        fsm_spec_inout['outputs'].append(('output{}'.format(i),
                                          output_pins[i]))
    for i in range(num_states):
        current_state = 'S{}'.format(i)
        next_state = 'S{}'.format((i + 1) % num_states)
        fsm_spec_inout['states'].append(current_state)
        output_pattern = ''
        for test_lane in test_lanes:
            random_1bit = '{}'.format(randint(0, 1))
            output_pattern += random_1bit
            test_lane += random_1bit
        transition = ['0' * len(input_pins), current_state, next_state,
                      output_pattern]
        fsm_spec_inout['transitions'].append(transition)

    test_patterns = []
    for i in range(len(output_pins)):
        temp_string = ''.join(test_lanes[i])
        test_patterns.append(np.array(bitstring_to_int(
            wave_to_bitstring(temp_string))))
    return fsm_spec_inout, test_patterns


def build_fsm_spec_free_run():
    """Build a spec that results in a free-running FSM.

    This will return an FSM spec with no given inputs.
    In this case, the FSM is a free running state machine. 
    A maximum number of states are deployed.

    Returns
    -------
    dict
        The FSM spec that can be consumed by the FSM generator.
    list
        The output patterns associated with this FSM spec.

    """
    input_pin = list(pin_dict.keys())[0]
    output_pins = list(pin_dict.keys())[1:interface_width]

    fsm_spec_inout = {'inputs': [],
                      'outputs': [],
                      'states': [],
                      'transitions': []}
    test_lanes = [[] for _ in range(len(output_pins))]
    num_states = FSM_MAX_NUM_STATES
    fsm_spec_inout['inputs'].append(('input0', input_pin))
    for i in range(len(output_pins)):
        fsm_spec_inout['outputs'].append(('output{}'.format(i),
                                          output_pins[i]))
    for i in range(num_states):
        current_state = 'S{}'.format(i)
        next_state = 'S{}'.format((i + 1) % num_states)
        fsm_spec_inout['states'].append(current_state)
        output_pattern = ''
        for test_lane in test_lanes:
            random_1bit = '{}'.format(randint(0, 1))
            output_pattern += random_1bit
            test_lane += random_1bit
        transition = ['-', current_state, next_state, output_pattern]
        fsm_spec_inout['transitions'].append(transition)

    test_patterns = []
    for i in range(len(output_pins)):
        temp_string = ''.join(test_lanes[i])
        test_patterns.append(np.array(bitstring_to_int(
            wave_to_bitstring(temp_string))))
    return fsm_spec_inout, test_patterns


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_num_samples():
    """Test for the Finite State Machine Generator class.

    In this test, the pattern generated by the FSM will be compared with the 
    one specified. We will test a minimum number of (FSM period + 1) samples,
    and a maximum number of samples. 10MHz and 100MHz clocks are tested
    for each case.

    """
    ol.download()

    rst, direction = list(pin_dict.keys())[1:3]
    print("\nConnect {} to GND, and {} to VCC.".format(rst, direction))
    input("Hit enter after done ...")

    fsm_spec_4_state, output_pattern, _, _ = build_fsm_spec_4_state(1)
    fsm_period = len(fsm_spec_4_state['states'])
    for num_samples in [fsm_period, MAX_NUM_TRACE_SAMPLES]:
        test_tile = np.array(output_pattern)
        golden_test_array = np.tile(test_tile, ceil(num_samples / 4))

        for fsm_frequency_mhz in [10, 100]:
            fsm_generator = FSMGenerator(mb_info)
            assert fsm_generator.status == 'RESET'

            fsm_generator.trace(use_analyzer=True,
                                num_analyzer_samples=num_samples)
            fsm_generator.setup(fsm_spec_4_state,
                                frequency_mhz=fsm_frequency_mhz)
            assert fsm_generator.status == 'READY'
            assert 'bram_data_buf' not in \
                   fsm_generator.logictools_controller.buffers, \
                'bram_data_buf is not freed after use.'

            fsm_generator.run()
            assert fsm_generator.status == 'RUNNING'

            test_string = ''
            for wavegroup in fsm_generator.waveform.waveform_dict['signal']:
                if wavegroup and wavegroup[0] == 'analysis':
                    for wavelane in wavegroup[1:]:
                        if wavelane['name'] == 'test':
                            test_string = wavelane['wave']
            test_array = np.array(bitstring_to_int(
                wave_to_bitstring(test_string)))

            assert np.array_equal(test_array,
                                  golden_test_array[:num_samples]), \
                'Data pattern not correct when running at {}MHz.'.format(
                    fsm_frequency_mhz)

            fsm_generator.stop()
            assert fsm_generator.status == 'READY'

            fsm_generator.reset()
            assert fsm_generator.status == 'RESET'

            del fsm_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_state_bits():
    """Test for the Finite State Machine Generator class.

    This test is similar to the first test, but in this test,
    we will test the case when the state bits are also used as outputs.

    """
    ol.download()

    rst, direction = list(pin_dict.keys())[1:3]
    print("\nConnect both {} and {} to GND.".format(rst, direction))
    input("Hit enter after done ...")

    fsm_spec_4_state, output_pattern, \
        state_bit0_pattern, state_bit1_pattern = build_fsm_spec_4_state(0)
    fsm_period = len(fsm_spec_4_state['states'])
    golden_test_array = np.array(output_pattern)
    golden_state_bit0_array = np.array(state_bit0_pattern)
    golden_state_bit1_array = np.array(state_bit1_pattern)

    for fsm_frequency_mhz in [10, 100]:
        fsm_generator = FSMGenerator(mb_info)
        fsm_generator.trace(use_analyzer=True,
                            num_analyzer_samples=fsm_period)
        fsm_generator.setup(fsm_spec_4_state,
                            use_state_bits=True,
                            frequency_mhz=fsm_frequency_mhz)
        fsm_generator.run()

        test_string = state_bit0_string = state_bit1_string = ''
        for wavegroup in fsm_generator.waveform.waveform_dict['signal']:
            if wavegroup and wavegroup[0] == 'analysis':
                for wavelane in wavegroup[1:]:
                    if wavelane['name'] == 'test':
                        test_string = wavelane['wave']
                    if wavelane['name'] == 'state_bit0':
                        state_bit0_string = wavelane['wave']
                    if wavelane['name'] == 'state_bit1':
                        state_bit1_string = wavelane['wave']
        test_array = np.array(bitstring_to_int(
            wave_to_bitstring(test_string)))
        state_bit0_array = np.array(bitstring_to_int(
            wave_to_bitstring(state_bit0_string)))
        state_bit1_array = np.array(bitstring_to_int(
            wave_to_bitstring(state_bit1_string)))

        assert np.array_equal(golden_test_array, test_array), \
            'Data pattern not correct when running at {}MHz.'.format(
                    fsm_frequency_mhz)
        assert np.array_equal(golden_state_bit0_array, state_bit0_array), \
            'State bit0 not correct when running at {}MHz.'.format(
                    fsm_frequency_mhz)
        assert np.array_equal(golden_state_bit1_array, state_bit1_array), \
            'State bit1 not correct when running at {}MHz.'.format(
                    fsm_frequency_mhz)

        fsm_generator.stop()
        fsm_generator.reset()
        del fsm_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_step():
    """Test for the Finite State Machine Generator class.

    This test is similar to the above test, but in this test,
    we will test the `step()` method, and ask users to change the input
    logic values in the middle of the test.

    """
    ol.download()

    rst, direction = list(pin_dict.keys())[1:3]
    print("")

    fsm_spec_4_state, output_pattern_up, \
        state_bit0_pattern_up, \
        state_bit1_pattern_up = build_fsm_spec_4_state(0)
    _, output_pattern_down, \
        state_bit0_pattern_down, \
        state_bit1_pattern_down = build_fsm_spec_4_state(1)
    output_pattern_down.append(output_pattern_down.pop(0))
    state_bit0_pattern_down.append(state_bit0_pattern_down.pop(0))
    state_bit1_pattern_down.append(state_bit1_pattern_down.pop(0))
    fsm_period = len(fsm_spec_4_state['states'])
    golden_test_array = np.array(output_pattern_up +
                                 output_pattern_down[1:])
    golden_state_bit0_array = np.array(state_bit0_pattern_up +
                                       state_bit0_pattern_down[1:])
    golden_state_bit1_array = np.array(state_bit1_pattern_up +
                                       state_bit1_pattern_down[1:])

    for fsm_frequency_mhz in [10, 100]:
        fsm_generator = FSMGenerator(mb_info)
        fsm_generator.trace(use_analyzer=True,
                            num_analyzer_samples=fsm_period)
        fsm_generator.setup(fsm_spec_4_state,
                            use_state_bits=True,
                            frequency_mhz=fsm_frequency_mhz)
        print("Connect both {} and {} to GND.".format(rst, direction))
        input("Hit enter after done ...")
        for _ in range(len(output_pattern_up)-1):
            fsm_generator.step()
        print("Connect {} to GND, and {} to VCC.".format(rst, direction))
        input("Hit enter after done ...")
        for _ in range(len(output_pattern_down)):
            fsm_generator.step()

        test_string = state_bit0_string = state_bit1_string = ''
        for wavegroup in fsm_generator.waveform.waveform_dict['signal']:
            if wavegroup and wavegroup[0] == 'analysis':
                for wavelane in wavegroup[1:]:
                    if wavelane['name'] == 'test':
                        test_string = wavelane['wave']
                    if wavelane['name'] == 'state_bit0':
                        state_bit0_string = wavelane['wave']
                    if wavelane['name'] == 'state_bit1':
                        state_bit1_string = wavelane['wave']
        test_array = np.array(bitstring_to_int(
            wave_to_bitstring(test_string)))
        state_bit0_array = np.array(bitstring_to_int(
            wave_to_bitstring(state_bit0_string)))
        state_bit1_array = np.array(bitstring_to_int(
            wave_to_bitstring(state_bit1_string)))

        assert np.array_equal(golden_test_array, test_array), \
            'Data pattern not correct when stepping at {}MHz.'.format(
                    fsm_frequency_mhz)
        assert np.array_equal(golden_state_bit0_array, state_bit0_array), \
            'State bit0 not correct when stepping at {}MHz.'.format(
                    fsm_frequency_mhz)
        assert np.array_equal(golden_state_bit1_array, state_bit1_array), \
            'State bit1 not correct when stepping at {}MHz.'.format(
                    fsm_frequency_mhz)

        fsm_generator.stop()
        fsm_generator.reset()
        del fsm_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_no_trace():
    """Test for the Finite State Machine Generator class.

    This is similar to the first test, but in this test,
    we will test the case when no analyzer is specified.

    """
    ol.download()

    fsm_spec_4_state, _, _, _ = build_fsm_spec_4_state(0)
    fsm_generator = FSMGenerator(mb_info)
    fsm_generator.trace(use_analyzer=False)
    fsm_generator.setup(fsm_spec_4_state)
    fsm_generator.run()

    exception_raised = False
    try:
        fsm_generator.show_waveform()
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception for show_waveform().'

    fsm_generator.reset()
    del fsm_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_num_states1():
    """Test for the Finite State Machine Generator class.

    The 4th test will check 1 and (MAX_NUM_STATES + 1) states. 
    These cases should raise exceptions. For these tests, we use the minimum 
    number of input and output pins.

    """
    ol.download()
    fsm_generator = None
    exception_raised = False
    fsm_spec_less_than_min_state, _ = build_fsm_spec_random(
        FSM_MIN_NUM_STATES - 1)
    fsm_spec_more_than_max_state, _ = build_fsm_spec_random(
        FSM_MAX_NUM_STATES + 1)
    for fsm_spec in [fsm_spec_less_than_min_state,
                     fsm_spec_more_than_max_state]:
        num_states = len(fsm_spec['states'])
        try:
            fsm_generator = FSMGenerator(mb_info)
            fsm_generator.trace(use_analyzer=True,
                                num_analyzer_samples=MAX_NUM_TRACE_SAMPLES)
            fsm_generator.setup(fsm_spec)
        except ValueError:
            exception_raised = True

        assert exception_raised, \
            'Should raise exception when ' \
            'there are {} states in the FSM.'.format(num_states)

        fsm_generator.reset()
        del fsm_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_num_states2():
    """Test for the Finite State Machine Generator class.

    This test will check 2 and MAX_NUM_STATES states. 
    These cases should be able to pass random tests. 
    For these tests, we use the minimum number of input and output pins.

    """
    ol.download()

    input_pin = list(pin_dict.keys())[0]
    print("\nConnect {} to GND, and disconnect other pins.".format(input_pin))
    input("Hit enter after done ...")

    for num_states in [2, FSM_MAX_NUM_STATES]:
        fsm_spec, test_pattern = build_fsm_spec_random(num_states)

        fsm_generator = FSMGenerator(mb_info)
        fsm_generator.trace(use_analyzer=True,
                            num_analyzer_samples=MAX_NUM_TRACE_SAMPLES)
        fsm_generator.setup(fsm_spec, frequency_mhz=100)
        fsm_generator.run()

        test_string = ''
        for wavegroup in fsm_generator.waveform.waveform_dict['signal']:
            if wavegroup and wavegroup[0] == 'analysis':
                for wavelane in wavegroup[1:]:
                    if wavelane['name'] == 'test':
                        test_string = wavelane['wave']
        test_array = np.array(bitstring_to_int(
            wave_to_bitstring(test_string)))

        period = num_states
        test_tile = np.array(test_pattern)

        golden_test_array = np.tile(test_tile,
                                    ceil(MAX_NUM_TRACE_SAMPLES / period))
        assert np.array_equal(test_array,
                              golden_test_array[:MAX_NUM_TRACE_SAMPLES]), \
            'Analysis not matching the generated pattern.'

        fsm_generator.stop()
        fsm_generator.reset()
        del fsm_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_max_in_out():
    """Test for the Finite State Machine Generator class.

    This test will test when maximum number of inputs and 
    outputs are used. At the same time, the largest available number of 
    states will be implemented.

    """
    ol.download()

    input_pins = list(pin_dict.keys())[:FSM_MAX_INPUT_BITS]
    print("\nConnect {} to GND.".format(input_pins))
    print("Disconnect all other pins.")
    input("Hit enter after done ...")

    fsm_spec_inout, test_patterns = build_fsm_spec_max_in_out()
    period = 2 ** (FSM_MAX_STATE_INPUT_BITS - FSM_MAX_INPUT_BITS) - 1
    num_output_pins = interface_width - FSM_MAX_INPUT_BITS

    fsm_generator = FSMGenerator(mb_info)
    fsm_generator.trace(use_analyzer=True,
                        num_analyzer_samples=MAX_NUM_TRACE_SAMPLES)
    fsm_generator.setup(fsm_spec_inout, frequency_mhz=100)
    fsm_generator.run()

    test_strings = ['' for _ in range(num_output_pins)]
    test_arrays = [[] for _ in range(num_output_pins)]
    for wavegroup in fsm_generator.waveform.waveform_dict['signal']:
        if wavegroup and wavegroup[0] == 'analysis':
            for wavelane in wavegroup[1:]:
                for j in range(num_output_pins):
                    if wavelane['name'] == 'output{}'.format(j):
                        test_strings[j] = wavelane['wave']
                        test_arrays[j] = np.array(bitstring_to_int(
                                        wave_to_bitstring(test_strings[j])))
                        break

    golden_arrays = [[] for _ in range(num_output_pins)]
    for i in range(num_output_pins):
        golden_arrays[i] = np.tile(test_patterns[i],
                                   ceil(MAX_NUM_TRACE_SAMPLES / period))
        assert np.array_equal(test_arrays[i],
                              golden_arrays[i][:MAX_NUM_TRACE_SAMPLES]), \
            'Output{} not matching the generated pattern.'.format(i)

    fsm_generator.stop()
    fsm_generator.reset()
    del fsm_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_fsm_free_run():
    """Test for the Finite State Machine Generator class.

    This will examine a special scenario where no inputs are given.
    In this case, the FSM is a free running state machine. Since the FSM 
    specification requires at least 1 input pin to be specified,  1 pin can 
    be used as `don't care` input, while all the other pins are used as 
    outputs. A maximum number of states are deployed.

    """
    ol.download()

    print("\nDisconnect all the pins.")
    input("Hit enter after done ...")

    fsm_spec_inout, test_patterns = build_fsm_spec_free_run()
    period = FSM_MAX_NUM_STATES
    num_output_pins = interface_width - 1
    fsm_generator = FSMGenerator(mb_info)
    fsm_generator.trace(use_analyzer=True,
                        num_analyzer_samples=period)
    fsm_generator.setup(fsm_spec_inout, frequency_mhz=100)
    fsm_generator.run()

    test_strings = ['' for _ in range(num_output_pins)]
    test_arrays = [[] for _ in range(num_output_pins)]
    for wavegroup in fsm_generator.waveform.waveform_dict['signal']:
        if wavegroup and wavegroup[0] == 'analysis':
            for wavelane in wavegroup[1:]:
                for j in range(num_output_pins):
                    if wavelane['name'] == 'output{}'.format(j):
                        test_strings[j] = wavelane['wave']
                        test_arrays[j] = np.array(bitstring_to_int(
                            wave_to_bitstring(test_strings[j])))
                        break

    golden_arrays = test_patterns
    for i in range(num_output_pins):
        assert np.array_equal(test_arrays[i], golden_arrays[i]), \
            'Output{} not matching the generated pattern.'.format(i)

    fsm_generator.stop()
    fsm_generator.reset()
    del fsm_generator
