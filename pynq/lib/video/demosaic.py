#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

from pynq import DefaultIP
from .common import HLS_AP_CTRL_REGISTER

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
    "reserved_0x20": {
        "address_offset": 0x20,
        "access": "read-write",
        "size": 32,
        "description": "Reserved register",
    },
    "bayer_phase": {
        "address_offset": 0x28,
        "access": "read-write",
        "size": 32,
        "description": "Bayer pattern phase select",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 4,
                "description": "Bayer pattern phase (0=RGGB, 1=GRBG, 2=GBRG, 3=BGGR)",
            },
        },
    },
}


class Demosaic(DefaultIP):
    """Driver for the Xilinx Video Demosaic IP.

    Converts Bayer-pattern RAW sensor data to RGB.

    """

    bindto = ["xilinx.com:ip:v_demosaic:1.1"]

    def __init__(self, description):
        description["registers"] = _registers
        super().__init__(description)

    def configure(self, width, height, bayer_phase=0x0):
        """Configure and enable the demosaic IP.

        Parameters
        ----------
        width : int
            Frame width in pixels
        height : int
            Frame height in lines
        bayer_phase : int
            Bayer sampling-grid start (reg 0x28, bits[1:0]): 0=RGGB,
            1=GRBG, 2=GBRG, 3=BGGR. Board- and sensor-orientation
            dependent; adjust if the demosaiced image has wrong hue.
        """
        rmap = self.register_map
        rmap.width = width
        rmap.height = height
        rmap.reserved_0x20 = 0x0
        rmap.bayer_phase = bayer_phase & 0x3
        rmap.ap_ctrl = 0x81  # ap_start=1, auto_restart=1 in a single write
