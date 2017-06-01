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
import pytest
from pynq.intf import Waveform


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


@pytest.mark.run(order=43)
def test_waveform():
    """Test for the Waveform class.

    Test the methods and attributes of the waveform class.

    """
    # Test correct data
    exception_raised = False
    correct_data = {'signal': [
        ['stimulus',
            {'name': 'clk0', 'pin': 'D0', 'wave': 'lh' * 64},
            {'name': 'clk1', 'pin': 'D1', 'wave': 'l.h.' * 32},
            {'name': 'clk2', 'pin': 'D2', 'wave': 'l...h...' * 16},
            {'name': 'clk3', 'pin': 'D3', 'wave': 'l.......h.......' * 8},
            {'name': 'clk4', 'pin': 'D4', 'wave': 'lh' * 32},
            {'name': 'clk5', 'pin': 'D5', 'wave': 'l.h.' * 32},
            {'name': 'clk6', 'pin': 'D6', 'wave': 'l...h...' * 16},
            {'name': 'clk7', 'pin': 'D7', 'wave': 'l.......h.......' * 8},
            {'name': 'clk8', 'pin': 'D8', 'wave': 'lh' * 16},
            {'name': 'clk9', 'pin': 'D9', 'wave': 'l.h.' * 32},
            {'name': 'clk10', 'pin': 'D10', 'wave': 'l...h...' * 16},
            {'name': 'clk11', 'pin': 'D11', 'wave': 'l.......h.......' * 8},
            {'name': 'clk12', 'pin': 'D12', 'wave': 'lh' * 8},
            {'name': 'clk13', 'pin': 'D13', 'wave': 'l.h.' * 32},
            {'name': 'clk14', 'pin': 'D14', 'wave': 'l...h...' * 16},
            {'name': 'clk15', 'pin': 'D15', 'wave': 'l.......h.......' * 8},
            {'name': 'clk16', 'pin': 'D16', 'wave': 'lh' * 4},
            {'name': 'clk17', 'pin': 'D17', 'wave': 'l.h.' * 32},
            {'name': 'clk18', 'pin': 'D18', 'wave': 'l...h...' * 16},
            {'name': 'clk19', 'pin': 'D19', 'wave': 'l.......h.......' * 8}],

        ['analysis',
            {'name': 'clk0', 'pin': 'D0'},
            {'name': 'clk1', 'pin': 'D1'},
            {'name': 'clk2', 'pin': 'D2'},
            {'name': 'clk3', 'pin': 'D3'},
            {'name': 'clk4', 'pin': 'D4'},
            {'name': 'clk5', 'pin': 'D5'},
            {'name': 'clk6', 'pin': 'D6'},
            {'name': 'clk7', 'pin': 'D7'},
            {'name': 'clk8', 'pin': 'D8'},
            {'name': 'clk9', 'pin': 'D9'},
            {'name': 'clk10', 'pin': 'D10'},
            {'name': 'clk11', 'pin': 'D11'},
            {'name': 'clk12', 'pin': 'D12'},
            {'name': 'clk13', 'pin': 'D13'},
            {'name': 'clk14', 'pin': 'D14'},
            {'name': 'clk15', 'pin': 'D15'},
            {'name': 'clk16', 'pin': 'D16'},
            {'name': 'clk17', 'pin': 'D17'},
            {'name': 'clk18', 'pin': 'D18'},
            {'name': 'clk19', 'pin': 'D19'}]],

        'foot': {'tock': 1, 'text': 'Loopback Test'},
        'head': {'tick': 1, 'text': 'Loopback Test'}}

    try:
        waveform = Waveform(correct_data,
                            stimulus_name='stimulus',
                            analysis_name='analysis')
        waveform.display()
    except Exception:
        exception_raised = True
    assert not exception_raised, 'Waveform display raised exception(s).'

    # Should raise exception when wavelane names are not unique
    wrong_data = {'signal': [
        ['stimulus',
         {'name': 'clk0', 'pin': 'D0', 'wave': 'lh' * 64},
         {'name': 'clk0', 'pin': 'D1', 'wave': 'l.h.' * 32}],
        ['analysis',
         {'name': 'clk0', 'pin': 'D0'},
         {'name': 'clk1', 'pin': 'D1'}]]}
    try:
        waveform = Waveform(wrong_data,
                            stimulus_name='stimulus',
                            analysis_name='analysis')
        waveform.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, \
        'Should raise exception on duplicated wavelane names.'

    # Should raise exception when wavelane pin labels are not unique
    wrong_data = {'signal': [
        ['stimulus',
         {'name': 'clk0', 'pin': 'D0', 'wave': 'lh' * 64},
         {'name': 'clk1', 'pin': 'D0', 'wave': 'l.h.' * 32}],
        ['analysis',
         {'name': 'clk0', 'pin': 'D0'},
         {'name': 'clk1', 'pin': 'D1'}]]}
    try:
        waveform = Waveform(wrong_data,
                            stimulus_name='stimulus',
                            analysis_name='analysis')
        waveform.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, \
        'Should raise exception on duplicated pin labels.'

    # Should raise exception when wavelane pin labels are not valid
    wrong_data = {'signal': [
        ['stimulus',
         {'name': 'clk0', 'pin': 'INVALID', 'wave': 'lh' * 64},
         {'name': 'clk1', 'pin': 'D1', 'wave': 'l.h.' * 32}],
        ['analysis',
         {'name': 'clk0', 'pin': 'D0'},
         {'name': 'clk1', 'pin': 'D1'}]]}
    try:
        waveform = Waveform(wrong_data,
                            stimulus_name='stimulus',
                            analysis_name='analysis')
        waveform.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, \
        'Should raise exception on invalid pin labels.'

    # Should raise exception when any wavelane is missing
    wrong_data = {'signal': [
        ['stimulus',
         {'name': 'clk0', 'pin': 'D0', 'wave': 'lh' * 64},
         {'name': 'clk1', 'pin': 'D1', 'wave': 'l.h.' * 32}]]}
    try:
        waveform = Waveform(wrong_data,
                            stimulus_name='stimulus',
                            analysis_name='analysis')
        waveform.display()
    except ValueError:
        exception_raised = True
    assert exception_raised, \
        'Should raise exception on missing wavelane group.'

    os.system("rm -rf ./js")
