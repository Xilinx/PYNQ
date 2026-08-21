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

    def configure(self, width, height, black_level=0, gains=(1.0, 1.0, 1.0),
                  gamma=1.0):
        """Configure the transfer curve and enable.

        Parameters
        ----------
        width : int
            Frame width in pixels
        height : int
            Frame height in lines
        black_level : int
            Black pedestal to subtract, in 8-bit counts. Raw sensors add
            a constant offset that no other stage removes.
        gains : tuple of float
            Per-channel (red, green, blue) gains, applied after the
            pedestal is subtracted. Scaling before the offset is removed
            would skew the ratios in the shadows.
        gamma : float
            Encoding gamma. 1.0 leaves the output scene-linear; 2.2
            approximates sRGB for display.
        """
        rmap = self.register_map
        rmap.width = width
        rmap.height = height
        rmap.video_format = 0x0
        self._set_curve(black_level, gains, gamma)
        rmap.ap_ctrl = 0x81  # ap_start=1, auto_restart=1 in a single write

    def _set_curve(self, black_level=0, gains=(1.0, 1.0, 1.0), gamma=1.0):
        """Write the transfer curve to all three channels.

        Entries are stored as uint16 but the value range is 8-bit, the
        same as the input.
        """
        if len(gains) != 3:
            raise ValueError(
                f"Expected (red, green, blue) gains, got {len(gains)} values")
        x = np.arange(256, dtype=np.float32)
        span = max(255 - black_level, 1)
        for channel, gain in zip(_CHANNEL_OFFSETS, gains):
            y = np.clip((x - black_level) * gain / span, 0.0, 1.0)
            if gamma != 1.0:
                y = y ** (1.0 / gamma)
            self._channel_view(channel)[:] = np.round(y * 255)

    def _channel_view(self, channel):
        """A writable uint16 view of one channel's 256-entry table."""
        if channel not in _CHANNEL_OFFSETS:
            raise ValueError(
                f"channel must be one of {list(_CHANNEL_OFFSETS)}")
        word_start = _CHANNEL_OFFSETS[channel] // 4
        return self.mmio.array[word_start:word_start + 128].view(np.uint16)

    def set_lut(self, channel, values):
        """Write a custom LUT for a single channel.

        Parameters
        ----------
        channel : str
            'r', 'g', or 'b'
        values : array-like
            256 uint16 values for the lookup table
        """
        values = np.asarray(values, dtype=np.uint16)
        if values.shape != (256,):
            raise ValueError("values must have exactly 256 entries")
        self._channel_view(channel)[:] = values
