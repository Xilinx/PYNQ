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
from random import randint
from copy import deepcopy
import numpy as np
import pytest
from pynq import Overlay
from pynq.tests.util import user_answer_yes
from pynq.lib.intf.pattern_builder import bitstring_to_int
from pynq.lib.intf.pattern_builder import wave_to_bitstring
from pynq.lib.intf import FSMBuilder
from pynq.lib.intf import PatternBuilder
from pynq.lib.intf import BooleanBuilder
from pynq.lib.intf import Intf
from pynq.lib.intf import ARDUINO
from pynq.lib.intf import PYNQZ1_DIO_SPECIFICATION
from pynq.lib.intf import MAX_NUM_PATTERN_SAMPLES
from pynq.lib.intf import FSM_MIN_STATE_BITS
from pynq.lib.intf import FSM_MAX_STATE_BITS
from pynq.lib.intf import FSM_MIN_NUM_STATES
from pynq.lib.intf import FSM_MAX_NUM_STATES
from pynq.lib.intf import FSM_MIN_INPUT_BITS
from pynq.lib.intf import FSM_MAX_INPUT_BITS
from pynq.lib.intf import FSM_MAX_STATE_INPUT_BITS
from pynq.lib.intf import FSM_MAX_OUTPUT_BITS


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    _ = Overlay('interface.bit')
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest all the builders together?")
if flag1:
    if_id = ARDUINO
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need interface overlay to run")
def test_all_builders():
    """Test all the builder classes implemented in the interface overlay.

    In this test, the boolean builders, pattern builders, and FSM builders
    are all instantiated. A maximum number of pattern samples are used.

    """
    ol = Overlay('interface.bit')
    ol.download()
    pin_dict = PYNQZ1_DIO_SPECIFICATION['traceable_outputs']
    interface_width = PYNQZ1_DIO_SPECIFICATION['interface_width']
    microblaze_intf = Intf(ARDUINO)
    num_samples = MAX_NUM_PATTERN_SAMPLES

    # Prepare the FSM builder
    all_pins = [k for k in list(pin_dict.keys())[:interface_width]]
    out = all_pins[0]
    rst, direction = all_pins[1:3]
    test_string1 = ''
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
    print(f"\nConnect {rst} to GND, and {direction} to VCC.")
    input("Hit enter after done ...")
    fsm = FSMBuilder(microblaze_intf, fsm_spec,
                     use_analyzer=True,
                     num_analyzer_samples=num_samples)
    fsm.config(frequency_mhz=10)

    # Prepare the pattern builder
    loopback1 = {'signal': [
        ['stimulus'],
        {},
        ['analysis']],
        'foot': {'tock': 1, 'text': 'Loopback Test'},
        'head': {'tick': 1, 'text': 'Loopback Test'}}

    for i in range(3, 7):
        wavelane1 = dict()
        wavelane2 = dict()
        wavelane1['name'] = f'clk{i}'
        wavelane2['name'] = f'clk{i}'
        wavelane1['pin'] = all_pins[i]
        wavelane2['pin'] = all_pins[i]
        loopback1['signal'][-1].append(wavelane2)
        if i % 4 == 0:
            wavelane1['wave'] = 'lh' * int(num_samples / 2)
        elif i % 4 == 1:
            wavelane1['wave'] = 'l.h.' * int(num_samples / 4)
        elif i % 4 == 2:
            wavelane1['wave'] = 'l...h...' * int(num_samples / 8)
        else:
            wavelane1['wave'] = 'l.......h.......' * int(num_samples / 16)
        loopback1['signal'][0].append(wavelane1)

    pg = PatternBuilder(microblaze_intf, loopback1,
                        stimulus_name='stimulus',
                        analysis_name='analysis',
                        use_analyzer=True,
                        num_analyzer_samples=num_samples)

    # Prepare the Boolean builders
    in_pins = all_pins[7:12]
    fx = list()
    fx.append(all_pins[12] + '=' + ('&'.join(in_pins)))
    fx.append(
        all_pins[13] + '=' + list(
            PYNQZ1_DIO_SPECIFICATION['non_traceable_inputs'].keys())[0])
    fx.append(
        list(PYNQZ1_DIO_SPECIFICATION['non_traceable_outputs'].keys())[0] +
        '=' + ('|'.join(in_pins)))

    print(f'Connect randomly {in_pins} to VCC or GND.')
    input(f'Hit enter after done ...')
    bgs = [BooleanBuilder(microblaze_intf, expr=expr,
                          use_analyzer=True,
                          num_analyzer_samples=num_samples) for expr in fx]

    # Run all the builder
    fsm.arm()
    pg.arm()
    for bg in bgs:
        bg.arm()
    microblaze_intf.start()

    # Tests data for FSM builder
    fsm.show_waveform()
    for wavegroup in fsm.waveform.waveform_dict['signal']:
        if wavegroup and wavegroup[0] == 'analysis':
            for wavelane in wavegroup[1:]:
                if wavelane['name'] == 'test':
                    test_string1 = wavelane['wave']
    test_array1 = np.array(bitstring_to_int(wave_to_bitstring(test_string1)))

    tile1 = np.array([1, 0, 0, 0])
    matched = False
    for delay in range(4):
        tile2 = np.roll(tile1, delay)
        candidate_array = np.tile(tile2, int(num_samples / 4))
        if np.array_equal(candidate_array[1:], test_array1[1:]):
            matched = True
            break
    assert matched, 'Analysis not matching the generated pattern.'

    # Test data for pattern builder
    pg.show_waveform()
    loopback2 = pg.waveform.waveform_dict

    list1 = list2 = list3 = list()
    for wavelane_group in loopback1['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            list1 = wavelane_group[1:]

    for wavelane_group in loopback2['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            list2 = wavelane_group[1:]
        elif wavelane_group and wavelane_group[0] == 'analysis':
            list3 = wavelane_group[1:]

    assert list1 == list2, \
        'Stimulus not equal in generated and captured patterns.'
    assert list2 == list3, \
        'Stimulus not equal to analysis in captured patterns.'

    # Test data for Boolean builders: only 1st expression is traceable
    for i in range(3):
        bgs[i].show_waveform()

    wavelanes_in = bgs[0].waveform.waveform_dict['signal'][0][1:]
    wavelanes_out = bgs[0].waveform.waveform_dict['signal'][-1][1:]
    expr = deepcopy(fx[0])
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
    assert eval(expr), f"Boolean builder fails for {fx[0]}."

    for bg in bgs:
        bg.stop()
    fsm.stop()
    pg.stop()

    # All the tests are finished
    microblaze_intf.reset_buffers()
    del fsm, pg, bgs
    ol.reset()
