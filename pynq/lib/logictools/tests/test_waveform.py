#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import os
from copy import deepcopy
import pytest
from pynq.lib.logictools import Waveform
from pynq.lib.logictools import PYNQZ1_LOGICTOOLS_SPECIFICATION




correct_data = {'signal': [
    ['stimulus'],
    {},
    ['analysis']],
    'foot': {'tock': 1},
    'head': {'text': 'Loopback Test'}}

pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
interface_width = PYNQZ1_LOGICTOOLS_SPECIFICATION['interface_width']
all_pins = [k for k in list(pin_dict.keys())[:interface_width]]
for i in range(interface_width):
    wavelane1 = dict()
    wavelane2 = dict()
    wavelane1['name'] = 'clk{}'.format(i)
    wavelane2['name'] = 'clk{}'.format(i)
    wavelane1['pin'] = all_pins[i]
    wavelane2['pin'] = all_pins[i]
    correct_data['signal'][-1].append(wavelane2)
    if i % 4 == 0:
        wavelane1['wave'] = 'lh' * 64
    elif i % 4 == 1:
        wavelane1['wave'] = 'l.h.' * 32
    elif i % 4 == 2:
        wavelane1['wave'] = 'l...h...' * 16
    else:
        wavelane1['wave'] = 'l.......h.......' * 8
    correct_data['signal'][0].append(wavelane1)


def test_waveform_correct():
    """Test for the Waveform class.

    Test whether a correct waveform data can be displayed without any 
    exception.

    """
    waveform = Waveform(correct_data,
                        stimulus_group_name='stimulus',
                        analysis_group_name='analysis')
    waveform.display()


def test_waveform_names():
    """Test for the Waveform class.

    Should raise exception when wavelane names are not unique.

    """
    exception_raised = False
    wrong_data = deepcopy(correct_data)
    wrong_data['signal'][0][2]['name'] = wrong_data['signal'][0][1]['name']
    try:
        waveform = Waveform(wrong_data,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis')
        waveform.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, \
        'Should raise exception on duplicated wavelane names.'


def test_waveform_pin_labels1():
    """Test for the Waveform class.

    Should raise exception when wavelane pin labels are not unique.

    """
    exception_raised = False
    wrong_data = deepcopy(correct_data)
    wrong_data['signal'][0][2]['pin'] = wrong_data['signal'][0][1]['pin']
    try:
        waveform = Waveform(wrong_data,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis')
        waveform.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, \
        'Should raise exception on duplicated pin labels.'


def test_waveform_pin_labels2():
    """Test for the Waveform class.

    Should raise exception when wavelane pin labels are not valid.

    """
    exception_raised = False
    wrong_data = deepcopy(correct_data)
    wrong_data['signal'][0][1]['pin'] = 'INVALID'
    try:
        waveform = Waveform(wrong_data,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis')
        waveform.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, \
        'Should raise exception on invalid pin labels.'


