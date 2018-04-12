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


import pynq
from pynq.lib import LogicToolsController
from pynq.lib import BooleanGenerator
from pynq.lib import PatternGenerator
from pynq.lib import TraceAnalyzer
from pynq.lib import FSMGenerator


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class LogicToolsOverlay(pynq.Overlay):
    """ The logictools overlay for the Pynq-Z1

    This overlay is implemented to control Boolean generators, 
    Pattern generators, FSM generators, and trace analyzers.

    Attributes
    ----------
    iop_pmodb : IOP
        IO processor connected to the PMODB interface.
    lcp_ar : LCP
        Logic controller processor connected to the Arduino interface.
    lcp_rp : LCP
        Logic controller processor connected to the Raspberrypi interface.

    """
    def __init__(self, bitfile, **kwargs):
        super().__init__(bitfile, **kwargs)
        if self.is_loaded():
            self.iop_pmodb.mbtype = "Pmod"
            self.lcp_ar.mbtype = "Logictools"
            self.lcp_rp.mbtype = "Logictools"

            self.PMODB = self.iop_pmodb.mb_info
            self.ARDUINO = self.lcp_ar.mb_info
            self.RASPBERRYPI = self.lcp_rp.mb_info

            self.boolean_generator = BooleanGenerator(self.ARDUINO)
            self.pattern_generator = PatternGenerator(self.ARDUINO)
            self.fsm_generator = FSMGenerator(self.ARDUINO)
            self.trace_analyzer = TraceAnalyzer(self.ARDUINO)
            self.logictools_controller = LogicToolsController(self.ARDUINO)
