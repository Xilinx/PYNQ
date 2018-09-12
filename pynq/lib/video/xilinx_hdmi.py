#   Copyright (c) 2018, Xilinx, Inc.
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

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

import cffi
import os
import warnings
from pynq import DefaultIP
from .frontend import VideoInFrontend, VideoOutFrontend
from .constants import LIB_SEARCH_PATH
from .common import VideoMode

_hdmi_lib_header = R"""
void* HdmiPhy_new(unsigned long BaseAddress);
void HdmiPhy_free(void* handle);
void HdmiPhy_handle_events(void* handle);
void HdmiPhy_report(void* handle);

void* HdmiRx_new(unsigned long BaseAddress, void* phy_handle);
void HdmiRx_free(void* handle);
void HdmiRx_handle_events(void* handle);
int HdmiRx_connected(void* handle);
int HdmiRx_ready(void* handle);
int HdmiRx_hsize(void* handle);
int HdmiRx_vsize(void* handle);
int HdmiRx_fps(void* handle);
void HdmiRx_report(void* handle);
void HdmiRx_load_edid(void* handle, unsigned char* data, unsigned length);
void HdmiRx_set_hpd(void* handle, unsigned value);

void* HdmiTx_new(unsigned long BaseAddress, void* phy_handle);
void HdmiTx_free(void* handle);
void HdmiTx_handle_events(void* handle);
int HdmiTx_connected(void* handle);
int HdmiTx_ready(void* handle);
int HdmiTx_set_format(void* handle, int hsize, int vsize, int fps);
unsigned long long HdmiTx_line_rate(void* handle);
int HdmiTx_start(void* handle);
void HdmiTx_stop(void* handle);
void HdmiTx_report(void* handle);
int HdmiTx_read_edid(void* handle, unsigned char* data);
void HdmiTx_dvi_mode(void* handle);
void HdmiTx_hdmi_mode(void* handle);
"""

_hdmi_ffi = cffi.FFI()
_hdmi_ffi.cdef(_hdmi_lib_header)

try:
    _hdmi_lib = _hdmi_ffi.dlopen(os.path.join(LIB_SEARCH_PATH, "libxhdmi.so"))
except:
    warnings.warn("Could not load Xilinx HDMI Library",
                  ResourceWarning)
    _hdmi_lib = None


class Vphy(DefaultIP):
    """Driver for Xilinx HDMI PHY

    """

    def __init__(self, description):
        """Create a new instance of the driver

        Can raise `RuntimeError` if the shared library was not found.

        Parameters
        ----------
        description : dict
            Entry in the ip_dict for the device

        """
        if _hdmi_lib is None:
            raise RuntimeError("No Xilinx HDMI Library")
        super().__init__(description)

    def initialize(self):
        self._virtaddr = self.mmio.array.ctypes.data
        self.handle = _hdmi_lib.HdmiPhy_new(self._virtaddr)

    def report(self):
        """Write the status of the PHY to stdout

        """
        _hdmi_lib.HdmiPhy_report(self.handle)

    bindto = ['xilinx.com:ip:vid_phy_controller:2.2']


class HdmiTxSs(DefaultIP, VideoOutFrontend):
    """Driver for the HDMI transmit subsystem

    """

    def __init__(self, description):
        """Create a new instance of the driver

        Can raise `RuntimeError` if the shared library was not found.

        Parameters
        ----------
        description : dict
            Entry in the ip_dict for the device

        """
        if _hdmi_lib is None:
            raise RuntimeError("No Xilinx HDMI Library")
        super().__init__(description)
        self._virtaddr = self.mmio.array.ctypes.data
        self.handle = None
        self.mode = None
        self.clocks = []

    def set_phy(self, phy):
        """Set the attached PHY

        The subsystem must be attached to a Xilinx HDMI PHY to operate

        Parameters
        ----------
        phy : HdmiVPhy
            The driver for the PHY

        """
        self.handle = _hdmi_lib.HdmiTx_new(self._virtaddr, phy.handle)

    def start(self):
        """Start the HDMI output

        The mode attribute and the PHY of the driver must be set before
        the transmitter can be started.

        """
        if self.handle is None:
            raise RuntimeError("Phy must be set before starting HDMI TX")
        if self.mode is None:
            raise RuntimeError("Mode must be set before starting HDMI TX")
        while not _hdmi_lib.HdmiTx_connected(self.handle):
            _hdmi_lib.HdmiTx_handle_events(self.handle)
        frequency = _hdmi_lib.HdmiTx_set_format(self.handle, self.mode.width,
                self.mode.height, self.mode.fps)
        if frequency == -1:
            raise RuntimeError("Resolution not supported")
        elif frequency == -2:
            raise RuntimeError("Could not set PHY clock")
        elif frequency == 0:
            raise RuntimeError("Display does not support HDMI 2.0")
        print("Frequency: {}".format(frequency))
        for c in self.clocks:
            c.set_clock(frequency, _hdmi_lib.HdmiTx_line_rate(self.handle))
        _hdmi_lib.HdmiTx_start(self.handle)
        # We need to wait for the stream to go down as well as up because
        # otherwise not enough events will happen to restart the output
        # when the resolution changes
        while _hdmi_lib.HdmiTx_ready(self.handle):
            _hdmi_lib.HdmiTx_handle_events(self.handle)
        while not _hdmi_lib.HdmiTx_ready(self.handle):
            _hdmi_lib.HdmiTx_handle_events(self.handle)

    def handle_events(self):
        """Ensure that interrupt handlers are called

         """
        _hdmi_lib.HdmiTx_handle_events(self.handle)

    def stop(self):
        """Stop the HDMI transmitter

        """
        _hdmi_lib.HdmiTx_stop(self.handle)

    def report(self):
        """Write the status of the transmitter to stdout

        """
        _hdmi_lib.HdmiTx_report(self.handle)

    def wait_for_connect(self):
        """Wait for a cable to connected to the transmitter port

        """
        while not _hdmi_lib.HdmiTx_connected(self.handle):
            _hdmi_lib.HdmiTx_handle_events(self.handle)

    def read_edid(self):
        """Return the EDID of the attached monitor

        Returns
        -------
        bytes : 256 bytes of EDID data

        """
        if not _hdmi_lib.HdmiTx_connected(self.handle):
            _hdmi_lib.HdmiTx_handle_events(self.handle)
        if not _hdmi_lib.HdmiTx_connected(self.handle):
            raise RuntimeError("Monitor not detected: use 'wait_for_connect'")
        buf = _hdmi_ffi.new("unsigned char[256]")
        error = _hdmi_lib.HdmiTx_read_edid(self.handle, buf)
        if error:
            raise RuntimeError("Could not read EDID")
        return bytes(buf[0:256])

    def HdmiMode(self):
        """Output using HDMI framing

        """
        _hdmi_lib.HdmiTx_hdmi_mode(self.handle)

    def DviMode(self):
        """Output using DVI framing

        """
        _hdmi_lib.HdmiTx_dvi_mode(self.handle)

    bindto = ['xilinx.com:ip:v_hdmi_tx_ss:3.1']


class HdmiRxSs(DefaultIP, VideoInFrontend):
    """Driver for the HDMI receiver subsystem

    """

    def __init__(self, description):
        """Create a new instance of the driver

        Can raise `RuntimeError` if the shared library was not found.

        Parameters
        ----------
        description : dict
            Entry in the ip_dict for the device

        """
        if _hdmi_lib is None:
            raise RuntimeError("No Xilinx HDMI Library")
        super().__init__(description)
        self._virtaddr = self.mmio.array.ctypes.data
        self.handle = None

    def set_phy(self, phy):
        """Set the attached PHY

        The subsystem must be attached to a Xilinx HDMI PHY to operate

        Parameters
        ----------
        phy : HdmiVPhy
            The driver for the PHY

        """
        self.handle = _hdmi_lib.HdmiRx_new(self._virtaddr, phy.handle)

    def start(self):
        """Start the receiver

        Blocks until the signal is stabilised

        """
        self.set_hpd(1)
        while not _hdmi_lib.HdmiRx_connected(self.handle):
            _hdmi_lib.HdmiRx_handle_events(self.handle)
        while not _hdmi_lib.HdmiRx_ready(self.handle):
            _hdmi_lib.HdmiRx_handle_events(self.handle)

    def stop(self):
        """Stop the receiver

        """
        pass

    @property
    def mode(self):
        """Return the mode of the attached device

        """
        if self.handle is None:
            raise RuntimeError("HDMI RX must be ready to get mode")
        if not _hdmi_lib.HdmiRx_ready(self.handle):
            raise RuntimeError("HDMI RX must be ready to get mode")
        return VideoMode(_hdmi_lib.HdmiRx_hsize(self.handle),
                _hdmi_lib.HdmiRx_vsize(self.handle), 24,
                _hdmi_lib.HdmiRx_fps(self.handle))

    def report(self):
        """Write the status of the receiver to stdout

         """
        _hdmi_lib.HdmiRx_report(self.handle)

    def load_edid(self, data):
        """Configure the EDID data exposed by the receiver

        The EDID should be between 128 and 256 bytes depending on the
        resolutions desired. In order to trigger the EDID to be read by
        the source the HPD line should be toggled after the EDID has
        been loaded.

        Parameters
        ----------
        data : bytes-like
            EDID data to load

        """
        if len(data) > 256:
            raise ValueError("Only EDIDs up to 256 bytes supported")
        buf = _hdmi_ffi.new("unsigned char [256]")
        buf[0:len(data)] = data
        _hdmi_lib.HdmiRx_load_edid(self.handle, buf, len(data))

    def set_hpd(self, value):
        """Set the Host presence detect line

        1 or True advertises the presence of a monitor to the source
        0 or False shows a disconnected cable

        Parameters
        ----------
        value : int or Boolean
            The desired value of the HPD line

        """
        _hdmi_lib.HdmiRx_set_hpd(self.handle, value)

    bindto = ['xilinx.com:ip:v_hdmi_rx_ss:3.1']
