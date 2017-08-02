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
from pynq.lib.logictools import LogicToolsController
from pynq.lib.logictools import TraceAnalyzer
from pynq.lib.logictools import ARDUINO
from pynq.lib.logictools import PYNQZ1_LOGICTOOLS_SPECIFICATION
from pynq.lib.logictools import MAX_NUM_TRACE_SAMPLES


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


try:
    ol = Overlay('logictools.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest trace analyzers?")
if flag1:
    mb_info = ARDUINO
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_trace_max_samples():
    """Test for the TraceAnalyzer class.

    The loop back data tests will be conducted for pattern generator and 
    FSM generator, hence this test only checks basic properties, attributes,
    etc. for the trace analyzer.
    
    The 1st group of tests will examine 0, or (MAX_NUM_TRACE_SAMPLES + 1)
    samples. An exception should be raised in these cases.

    """
    ol.download()
    for num_samples in [0, MAX_NUM_TRACE_SAMPLES + 1]:
        exception_raised = False
        analyzer = None
        try:
            analyzer = TraceAnalyzer(mb_info)
            analyzer.setup(num_analyzer_samples=num_samples)
        except ValueError:
            exception_raised = True
        finally:
            analyzer.logictools_controller.reset_buffers()
            analyzer.__del__()
        assert exception_raised, \
            'Should raise exception when capturing {} sample(s).'.format(
                num_samples)


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_trace_run():
    """Test for the TraceAnalyzer class.

    This group of tests will examine 1, 2, or MAX_NUM_TRACE_SAMPLES
    samples. No exception should be raised in these cases. For each case,
    all the methods are tested, and the states of the trace analyzer have been
    checked.

    """
    ol.download()
    for num_samples in [1, 2, MAX_NUM_TRACE_SAMPLES]:
        analyzer = TraceAnalyzer(mb_info)
        assert analyzer.status == 'RESET'

        analyzer.setup(num_analyzer_samples=num_samples)
        assert analyzer.status == 'READY'

        analyzer.run()
        analyzer.stop()
        assert analyzer.status == 'READY'

        analyzer.analyze(0)
        analyzer.reset()
        assert analyzer.status == 'RESET'

        analyzer.__del__()


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_trace_step():
    """Test for the TraceAnalyzer class.

    This group of tests will try to analyze 1, 2, or MAX_NUM_TRACE_SAMPLES
    samples. No exception should be raised in these cases. For each case,
    all the methods are tested, and the states of the trace analyzer have been
    checked.

    """
    ol.download()
    for num_samples in [1, 2, MAX_NUM_TRACE_SAMPLES]:
        analyzer = TraceAnalyzer(mb_info)
        assert analyzer.status == 'RESET'

        analyzer.setup(num_analyzer_samples=MAX_NUM_TRACE_SAMPLES)
        assert analyzer.status == 'READY'

        analyzer.run()
        analyzer.stop()
        assert analyzer.status == 'READY'

        analyzer.analyze(num_samples)
        analyzer.reset()
        assert analyzer.status == 'RESET'

        analyzer.__del__()


@pytest.mark.skipif(not flag, reason="need correct overlay to run")
def test_trace_buffers():
    """Test for the TraceAnalyzer class.

    This group of tests will examine a scenario where 2 trace analyzers are
    instantiated. This should be no problem since the trace analyzer is 
    implemented as a singleton.
    
    """
    ol.download()
    num_samples = sorted(
        sample([k for k in range(MAX_NUM_TRACE_SAMPLES)], 2))
    analyzers = [None, None]
    for i in range(2):
        analyzers[i] = TraceAnalyzer(mb_info)
        analyzers[i].setup(num_analyzer_samples=num_samples[i])
        assert 'trace_buf' in analyzers[i].logictools_controller.buffers, \
            'Analyzer with {} samples does not allocate trace_buf.'.format(
                num_samples[i])

        analyzers[i].run()
        analyzers[i].analyze(0)
        assert analyzers[i].samples is not None, \
            'Analyzer with {} samples has empty raw samples.'.format(
                num_samples[i])

        analyzers[i].stop()
        assert len(analyzers[i].samples) == num_samples[i], \
            'Analyzer with {} samples gets wrong number of samples.'.format(
                num_samples[i])

        analyzers[i].reset()
        analyzers[i].__del__()
        assert 'trace_buf' not in analyzers[i].logictools_controller.buffers, \
            'trace_buf is not freed after use.'
