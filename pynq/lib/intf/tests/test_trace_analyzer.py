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


import pytest
from pynq import Overlay
from pynq.intf.intf_const import PYNQZ1_DIO_SPECIFICATION
from pynq.intf import TraceAnalyzer


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


ol = Overlay('interface.bit')


@pytest.mark.run(order=44)
def test_trace_analyzer():
    """Test for the TraceAnalyzer class.

    The loop back data tests will be conducted for pattern generator and 
    FSM generator, hence this test only checks basic properties, attributes,
    etc. for the trace analyzer.

    """
    if_id = 3
    intf_spec = PYNQZ1_DIO_SPECIFICATION
    analyzer = TraceAnalyzer(if_id, trace_spec=intf_spec)

    analyzer.config()
    assert 'trace_buf' in analyzer.intf.buffers, \
        'trace_buf is not allocated before use.'

    analyzer.arm()
    analyzer.run()
    analyzer.analyze()
    assert analyzer.samples is not None, \
        'raw samples are empty in the trace analyzer.'
    analyzer.stop()
    analyzer.reset()
    assert 'trace_buf' not in analyzer.intf.buffers, \
        'trace_buf is not freed after use.'
    del analyzer
    ol.reset()




