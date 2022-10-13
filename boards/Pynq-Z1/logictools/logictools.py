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
    pmoda : IOP
         IO processor connected to the PMODA interface.
    pmodb : IOP
         IO processor connected to the PMODB interface.
    arduino : LCP
         Logic controller processor connected to the Arduino interface.

    """
    def __init__(self, bitfile, **kwargs):
        super().__init__(bitfile, **kwargs)
        if self.is_loaded():
            self.iop_pmoda.mbtype = "Pmod"
            self.iop_pmodb.mbtype = "Pmod"
            self.lcp_ar.mbtype = "Logictools"

            self.PMODA = self.iop_pmoda.mb_info
            self.PMODB = self.iop_pmodb.mb_info
            self.ARDUINO = self.lcp_ar.mb_info

            self.boolean_generator = BooleanGenerator(self.ARDUINO)
            self.pattern_generator = PatternGenerator(self.ARDUINO)
            self.fsm_generator = FSMGenerator(self.ARDUINO)
            self.trace_analyzer = TraceAnalyzer(self.ARDUINO)
            self.logictools_controller = LogicToolsController(self.ARDUINO)


