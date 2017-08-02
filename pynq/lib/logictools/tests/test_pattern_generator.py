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


from random import randint
from copy import deepcopy
import pytest
from pynq import Overlay
from pynq.tests.util import user_answer_yes
from pynq.lib.logictools import PatternGenerator
from pynq.lib.logictools.waveform import wave_to_bitstring
from pynq.lib.logictools import ARDUINO
from pynq.lib.logictools import PYNQZ1_LOGICTOOLS_SPECIFICATION
from pynq.lib.logictools import MAX_NUM_PATTERN_SAMPLES


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    ol = Overlay('logictools.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest pattern generator?")
if flag1:
    mb_info = ARDUINO
flag = flag0 and flag1


def build_loopback_pattern(num_samples):
    """Method to construct loopback signal patterns.

    Each loopback signal channel is simulating a clock signal with a specific
    frequency. And the number of samples can be specified.

    Parameters
    ----------
    num_samples : int
        The number of samples can be looped.

    Returns
    -------
    dict
        A waveform dictionary that can be recognized by WaveDrom.

    """
    loopback_pattern = {'signal': [
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
        loopback_pattern['signal'][-1].append(wavelane2)
        if i % 4 == 0:
            wavelane1['wave'] = 'lh' * int(num_samples / 2)
        elif i % 4 == 1:
            wavelane1['wave'] = 'l.h.' * int(num_samples / 4)
        elif i % 4 == 2:
            wavelane1['wave'] = 'l...h...' * int(num_samples / 8)
        else:
            wavelane1['wave'] = 'l.......h.......' * int(num_samples / 16)
        loopback_pattern['signal'][0].append(wavelane1)
    return loopback_pattern


def build_random_pattern(num_samples):
    """Method to construct random signal patterns.

    Each random signal channel is a collection of random bits. 
    And the number of samples can be specified.

    Parameters
    ----------
    num_samples : int
        The number of samples can be looped.

    Returns
    -------
    dict
        A waveform dictionary that can be recognized by WaveDrom.

    """
    random_pattern = {'signal': [
        ['stimulus'],
        {},
        ['analysis']],
        'foot': {'tock': 1},
        'head': {'text': 'Random Test'}}
    pin_dict = PYNQZ1_LOGICTOOLS_SPECIFICATION['traceable_outputs']
    interface_width = PYNQZ1_LOGICTOOLS_SPECIFICATION['interface_width']
    all_pins = [k for k in list(pin_dict.keys())[:interface_width]]
    for i in range(interface_width):
        wavelane1 = dict()
        wavelane2 = dict()
        wavelane1['name'] = 'signal{}'.format(i)
        wavelane2['name'] = 'signal{}'.format(i)
        wavelane1['pin'] = all_pins[i]
        wavelane2['pin'] = all_pins[i]
        random_pattern['signal'][-1].append(wavelane2)
        rand_list = [str(randint(0, 1)) for _ in range(num_samples)]
        rand_str = ''.join(rand_list)
        wavelane1['wave'] = rand_str.replace('0', 'l').replace('1', 'h')
        random_pattern['signal'][0].append(wavelane1)
    return random_pattern


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_pattern_state():
    """Test for the PatternGenerator class.

    This test will test a set of loopback signals. Each lane is
    simulating a clock of a specific frequency.

    """
    ol.download()
    print("\nDisconnect all the pins.")
    input("Hit enter after done ...")

    num_samples = 128
    loopback_sent = build_loopback_pattern(num_samples)
    pattern_generator = PatternGenerator(mb_info)
    assert pattern_generator.status == 'RESET'

    pattern_generator.trace(use_analyzer=True,
                            num_analyzer_samples=num_samples)
    pattern_generator.setup(loopback_sent,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis')
    assert pattern_generator.status == 'READY'

    pattern_generator.run()
    assert pattern_generator.status == 'RUNNING'

    loopback_recv = pattern_generator.waveform.waveform_dict
    list1 = list2 = list3 = list()
    for wavelane_group in loopback_sent['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            list1 = wavelane_group[1:]

    for wavelane_group in loopback_recv['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            list2 = wavelane_group[1:]
        elif wavelane_group and wavelane_group[0] == 'analysis':
            list3 = wavelane_group[1:]

    assert list1 == list2, \
        'Stimulus not equal in generated and captured patterns.'
    assert list2 == list3, \
        'Stimulus not equal to analysis in captured patterns.'

    pattern_generator.stop()
    assert pattern_generator.status == 'READY'
    pattern_generator.reset()
    assert pattern_generator.status == 'RESET'
    del pattern_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_pattern_no_trace():
    """Test for the PatternGenerator class.

    This test will test the case when no analyzer is used. Exception
    should be raised when users want to show the waveform.

    """
    ol.download()
    num_samples = 128
    loopback_sent = build_loopback_pattern(num_samples)
    pattern_generator = PatternGenerator(mb_info)
    pattern_generator.trace(use_analyzer=False,
                            num_analyzer_samples=num_samples)
    exception_raised = False
    try:
        pattern_generator.setup(loopback_sent,
                                stimulus_group_name='stimulus',
                                analysis_group_name='analysis')
        pattern_generator.run()
        pattern_generator.show_waveform()
    except ValueError:
        exception_raised = True
    assert exception_raised, 'Should raise exception for show_waveform().'

    pattern_generator.reset()
    del pattern_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_pattern_num_samples():
    """Test for the PatternGenerator class.

    This test will examine 0 sample and more than the maximum number 
    of samples. In these cases, exception should be raised.

    Here the `MAX_NUM_PATTERN_SAMPLE` is used for display purpose. The maximum
    number of samples that can be captured by the trace analyzer is defined
    as `MAX_NUM_TRACE_SAMPLES`.

    """
    ol.download()
    for num_samples in [0, MAX_NUM_PATTERN_SAMPLES+1]:
        loopback_sent = build_loopback_pattern(num_samples)
        pattern_generator = PatternGenerator(mb_info)
        exception_raised = False
        try:
            pattern_generator.trace(use_analyzer=True,
                                    num_analyzer_samples=num_samples)
            pattern_generator.setup(loopback_sent,
                                    stimulus_group_name='stimulus',
                                    analysis_group_name='analysis')
        except ValueError:
            exception_raised = True
        assert exception_raised, 'Should raise exception if number of ' \
                                 'samples is out of range.'

        pattern_generator.reset()
        del pattern_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_pattern_random():
    """Test for the PatternGenerator class.

    This test will examine 1 sample, and a maximum number of samples.
    For theses cases, random signals will be used, and all the 
    pins will be used to build the pattern.

    """
    ol.download()
    for num_samples in [1, MAX_NUM_PATTERN_SAMPLES]:
        loopback_sent = build_random_pattern(num_samples)
        pattern_generator = PatternGenerator(mb_info)
        pattern_generator.trace(use_analyzer=True,
                                num_analyzer_samples=num_samples)
        pattern_generator.setup(loopback_sent,
                                stimulus_group_name='stimulus',
                                analysis_group_name='analysis',
                                frequency_mhz=100)
        pattern_generator.run()

        loopback_recv = pattern_generator.waveform.waveform_dict
        list1 = list2 = list3 = list()
        for wavelane_group in loopback_sent['signal']:
            if wavelane_group and wavelane_group[0] == 'stimulus':
                for i in wavelane_group[1:]:
                    temp = deepcopy(i)
                    temp['wave'] = wave_to_bitstring(i['wave'])
                    list1.append(temp)

        for wavelane_group in loopback_recv['signal']:
            if wavelane_group and wavelane_group[0] == 'stimulus':
                for i in wavelane_group[1:]:
                    temp = deepcopy(i)
                    temp['wave'] = wave_to_bitstring(i['wave'])
                    list2.append(temp)
            elif wavelane_group and wavelane_group[0] == 'analysis':
                for i in wavelane_group[1:]:
                    temp = deepcopy(i)
                    temp['wave'] = wave_to_bitstring(i['wave'])
                    list3.append(temp)
        assert list1 == list2, \
            'Stimulus not equal in generated and captured patterns.'
        assert list2 == list3, \
            'Stimulus not equal to analysis in captured patterns.'

        pattern_generator.stop()
        pattern_generator.reset()
        del pattern_generator


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_pattern_step():
    """Test for the PatternGenerator class.

    This test will examine a moderate number of 128 samples (in order
    to shorten testing time). For theses cases, random signals will be used, 
    and all the pins will be used to build the pattern. Each sample is 
    captured after advancing the `step()`.

    """
    ol.download()
    num_samples = 128
    loopback_sent = build_random_pattern(num_samples)
    pattern_generator = PatternGenerator(mb_info)
    pattern_generator.trace(use_analyzer=True,
                            num_analyzer_samples=num_samples)
    pattern_generator.setup(loopback_sent,
                            stimulus_group_name='stimulus',
                            analysis_group_name='analysis',
                            frequency_mhz=100)

    for _ in range(num_samples):
        pattern_generator.step()

    loopback_recv = pattern_generator.waveform.waveform_dict
    list1 = list2 = list3 = list()
    for wavelane_group in loopback_sent['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            for i in wavelane_group[1:]:
                temp = deepcopy(i)
                temp['wave'] = wave_to_bitstring(i['wave'])
                list1.append(temp)

    for wavelane_group in loopback_recv['signal']:
        if wavelane_group and wavelane_group[0] == 'stimulus':
            for i in wavelane_group[1:]:
                temp = deepcopy(i)
                temp['wave'] = wave_to_bitstring(i['wave'])
                list2.append(temp)
        elif wavelane_group and wavelane_group[0] == 'analysis':
            for i in wavelane_group[1:]:
                temp = deepcopy(i)
                temp['wave'] = wave_to_bitstring(i['wave'])
                list3.append(temp)
    assert list1 == list2, \
        'Stimulus not equal in generated and captured patterns.'
    assert list2 == list3, \
        'Stimulus not equal to analysis in captured patterns.'

    pattern_generator.stop()
    pattern_generator.reset()
    del pattern_generator
