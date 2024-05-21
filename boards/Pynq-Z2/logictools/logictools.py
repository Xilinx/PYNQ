#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pynq
from pynq.lib import LogicToolsController
from pynq.lib import BooleanGenerator
from pynq.lib import PatternGenerator
from pynq.lib import TraceAnalyzer
from pynq.lib import FSMGenerator




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


