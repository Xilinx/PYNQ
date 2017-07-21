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


import os
from copy import deepcopy
import pytest
from pynq.lib.logictools import Waveform
from pynq.lib.logictools import PYNQZ1_LOGICTOOLS_SPECIFICATION


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


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
