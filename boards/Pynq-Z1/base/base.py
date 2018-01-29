#   Copyright (c) 2017, Xilinx, Inc.
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
import pynq.lib
import pynq.lib.video
import pynq.lib.audio
from .constants import *
from pynq.lib.logictools import TraceAnalyzer


__author__ = "Peter Ogden"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


class BaseOverlay(pynq.Overlay):
    """ The Base overlay for the Pynq-Z1

    This overlay is designed to interact with all of the on board peripherals
    and external interfaces of the Pynq-Z1 board. It exposes the following
    attributes:

    Attributes
    ----------
    iop_pmoda : IOP
         IO processor connected to the PMODA interface
    iop_pmodb : IOP
         IO processor connected to the PMODB interface
    iop_arduino : IOP
         IO processor connected to the Arduino/ChipKit interface
    trace_pmoda : pynq.logictools.TraceAnalyzer
        Trace analyzer block on PMODA interface, controlled by PS.
    trace_arduino : pynq.logictools.TraceAnalyzer
        Trace analyzer block on Arduino interface, controlled by PS. 
    leds : AxiGPIO
         4-bit output GPIO for interacting with the green LEDs LD0-3
    buttons : AxiGPIO
         4-bit input GPIO for interacting with the buttons BTN0-3
    switches : AxiGPIO
         2-bit input GPIO for interacting with the switches SW0 and SW1
    rgbleds : [pynq.board.RGBLED]
         Wrapper for GPIO for LD4 and LD5 multicolour LEDs
    video : pynq.lib.video.HDMIWrapper
         HDMI input and output interfaces
    audio : pynq.lib.audio.Audio
         Headphone jack and on-board microphone

    """

    def __init__(self, bitfile, **kwargs):
        super().__init__(bitfile, **kwargs)
        if self.is_loaded():
            self.iop_pmoda.mbtype = "Pmod"
            self.iop_pmodb.mbtype = "Pmod"
            self.iop_arduino.mbtype = "Arduino"

            self.PMODA = self.iop_pmoda.mb_info
            self.PMODB = self.iop_pmodb.mb_info
            self.ARDUINO = self.iop_arduino.mb_info

            self.audio = self.audio_direct_0
            self.leds = self.leds_gpio.channel1
            self.switches = self.switches_gpio.channel1
            self.buttons = self.btns_gpio.channel1
            self.leds.setlength(4)
            self.switches.setlength(2)
            self.buttons.setlength(4)
            self.leds.setdirection("out")
            self.switches.setdirection("in")
            self.buttons.setdirection("in")
            self.rgbleds = ([None] * 4) + [pynq.lib.RGBLED(i)
                                           for i in range(4, 6)]

            self.trace_pmoda = TraceAnalyzer(
                self.trace_analyzer_pmoda.description['ip'],
                PYNQZ1_PMODA_SPECIFICATION)
            self.trace_arduino = TraceAnalyzer(
                self.trace_analyzer_arduino.description['ip'],
                PYNQZ1_ARDUINO_SPECIFICATION)
