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
import pytest
from pynq import Overlay
from pynq.tests.util import user_answer_yes
from pynq.lib.intf import TraceAnalyzer
from pynq.lib.intf import Intf
from pynq.lib.intf import ARDUINO
from pynq.lib.intf import PYNQZ1_DIO_SPECIFICATION
from pynq.lib.intf import MAX_NUM_TRACE_SAMPLES


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    _ = Overlay('interface.bit')
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest trace analyzers?")
if flag1:
    if_id = ARDUINO
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need interface overlay to run")
def test_trace_analyzer():
    """Test for the TraceAnalyzer class.

    The loop back data tests will be conducted for pattern generator and 
    FSM generator, hence this test only checks basic properties, attributes,
    etc. for the trace analyzer.
    
    The 1st group of tests will examine 0, or (MAX_NUM_TRACE_SAMPLES + 1)
    samples. An exception should be raised in these cases.

    The 2nd group of tests will examine 1, 2, or MAX_NUM_TRACE_SAMPLES
    samples. No exception should be raised in these cases.

    The 3rd group of tests will examine a special scenario where 2
    trace analyzers are instantiated. The 2nd instantiated analyzer asks for 
    fewer samples than the 1st analyzer, then the 1st analyzer can still see 
    its original number of samples.

    """
    ol = Overlay('interface.bit')
    ol.download()

    # Test 1: 0 / (MAX_NUM_TRACE_SAMPLES + 1) samples
    intf_spec = PYNQZ1_DIO_SPECIFICATION
    for num_samples in [0, MAX_NUM_TRACE_SAMPLES + 1]:
        exception_raised = False
        analyzer = None
        try:
            analyzer = TraceAnalyzer(ARDUINO, num_samples=num_samples,
                                     trace_spec=intf_spec)
        except ValueError:
            exception_raised = True
        finally:
            if analyzer:
                analyzer.intf.reset_buffers()
            del analyzer
        assert exception_raised, \
            f'Should raise exception when capturing {num_samples} sample(s).'

    # Test 2: 1, 2, or MAX_NUM_TRACE_SAMPLES samples
    for num_samples in [1, 2, MAX_NUM_TRACE_SAMPLES]:
        analyzer = TraceAnalyzer(ARDUINO, num_samples=num_samples,
                                 trace_spec=intf_spec)
        assert 'trace_buf' in analyzer.intf.buffers, \
            'trace_buf is not allocated before use.'
        analyzer.arm()
        analyzer.start()
        analyzer.analyze()
        assert analyzer.samples is not None, \
            'raw samples are empty in the trace analyzer.'
        analyzer.stop()
        assert 'trace_buf' not in analyzer.intf.buffers, \
            'trace_buf is not freed after use.'
        del analyzer

    # Test 3: later analyzer asks for fewer samples then previous analyzer
    microblaze_intf = Intf(ARDUINO)
    num_samples = sorted(
        sample([k for k in range(MAX_NUM_TRACE_SAMPLES)], 2))
    analyzers = [None, None]
    for i in range(2):
        analyzers[i] = TraceAnalyzer(microblaze_intf,
                                     num_samples=num_samples[i],
                                     trace_spec=PYNQZ1_DIO_SPECIFICATION)
        analyzers[i].arm()
        analyzers[i].start()
        analyzers[i].analyze()
        analyzers[i].stop(free_buffer=False)
        assert len(analyzers[i].samples) == num_samples[i], \
            f'Analyzer {i} not getting correct number of samples.'
    microblaze_intf.reset_buffers()

    ol.reset()
