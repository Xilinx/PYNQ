#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import numpy as np
from pynq import DefaultIP
from .common import HLS_AP_CTRL_REGISTER

_CHANNEL_OFFSETS = {'r': 0x800, 'g': 0x1000, 'b': 0x1800}

_registers = {
    **HLS_AP_CTRL_REGISTER,
    "width": {
        "address_offset": 0x10,
        "access": "read-write",
        "size": 32,
        "description": "Frame width in pixels",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Frame width in pixels",
            },
        },
    },
    "height": {
        "address_offset": 0x18,
        "access": "read-write",
        "size": 32,
        "description": "Frame height in lines",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Frame height in lines",
            },
        },
    },
    "video_format": {
        "address_offset": 0x20,
        "access": "read-write",
        "size": 32,
        "description": "Video format select",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Color format select",
            },
        },
    },
}


class GammaLut(DefaultIP):
    """Driver for the Xilinx Video Gamma LUT IP.

    Provides per-channel 256-entry lookup tables for gamma correction.
    Each entry is a 16-bit value. The default configuration writes a
    linear (identity) LUT.

    """

    bindto = ["xilinx.com:ip:v_gamma_lut:1.1"]

    def __init__(self, description):
        description["registers"] = _registers
        super().__init__(description)

    def configure(self, width, height):
        """Configure with identity LUT and enable.

        Parameters
        ----------
        width : int
            Frame width in pixels
        height : int
            Frame height in lines
        """
        rmap = self.register_map
        rmap.width = width
        rmap.height = height
        rmap.video_format = 0x0
        self._set_linear_lut()
        rmap.ap_ctrl = 0x81  # ap_start=1, auto_restart=1 in a single write

    def _set_linear_lut(self):
        """Write identity (linear ramp) LUT to all three channels."""
        arr = self.mmio.array
        ramp = np.arange(256, dtype=np.uint16)
        for base in _CHANNEL_OFFSETS.values():
            word_start = base // 4
            u16 = arr[word_start:word_start + 128].view(np.uint16)
            u16[:] = ramp

    def set_lut(self, channel, values):
        """Write a custom LUT for a single channel.

        Parameters
        ----------
        channel : str
            'r', 'g', or 'b'
        values : array-like
            256 uint16 values for the lookup table
        """
        if channel not in _CHANNEL_OFFSETS:
            raise ValueError(f"channel must be one of {list(_CHANNEL_OFFSETS)}")
        values = np.asarray(values, dtype=np.uint16)
        if values.shape != (256,):
            raise ValueError("values must have exactly 256 entries")
        base = _CHANNEL_OFFSETS[channel]
        word_start = base // 4
        arr = self.mmio.array
        u16 = arr[word_start:word_start + 128].view(np.uint16)
        u16[:] = values
