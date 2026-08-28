#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

from pynq import DefaultIP
from .common import HLS_AP_CTRL_REGISTER

_registers = {
    **HLS_AP_CTRL_REGISTER,
    "in_video_format": {
        "address_offset": 0x10,
        "access": "read-write",
        "size": 32,
        "description": "Input Video Format",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 8,
                "description": "Input video format select",
            },
        },
    },
    "out_video_format": {
        "address_offset": 0x18,
        "access": "read-write",
        "size": 32,
        "description": "Output Video Format",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 8,
                "description": "Output video format select",
            },
        },
    },
    "width": {
        "address_offset": 0x20,
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
        "address_offset": 0x28,
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
    "col_start": {
        "address_offset": 0x30,
        "access": "read-write",
        "size": 32,
        "description": "Column Start",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Column start position",
            },
        },
    },
    "col_end": {
        "address_offset": 0x38,
        "access": "read-write",
        "size": 32,
        "description": "Column End",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Column end position",
            },
        },
    },
    "row_start": {
        "address_offset": 0x40,
        "access": "read-write",
        "size": 32,
        "description": "Row Start",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Row start position",
            },
        },
    },
    "row_end": {
        "address_offset": 0x48,
        "access": "read-write",
        "size": 32,
        "description": "Row End",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Row end position",
            },
        },
    },
    "k11": {
        "address_offset": 0x50,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K11",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K11 (0x1000 = 1.0)",
            },
        },
    },
    "k12": {
        "address_offset": 0x58,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K12",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K12 (0x1000 = 1.0)",
            },
        },
    },
    "k13": {
        "address_offset": 0x60,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K13",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K13 (0x1000 = 1.0)",
            },
        },
    },
    "k21": {
        "address_offset": 0x68,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K21",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K21 (0x1000 = 1.0)",
            },
        },
    },
    "k22": {
        "address_offset": 0x70,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K22",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K22 (0x1000 = 1.0)",
            },
        },
    },
    "k23": {
        "address_offset": 0x78,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K23",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K23 (0x1000 = 1.0)",
            },
        },
    },
    "k31": {
        "address_offset": 0x80,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K31",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K31 (0x1000 = 1.0)",
            },
        },
    },
    "k32": {
        "address_offset": 0x88,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K32",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K32 (0x1000 = 1.0)",
            },
        },
    },
    "k33": {
        "address_offset": 0x90,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix coefficient K33",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K33 (0x1000 = 1.0)",
            },
        },
    },
    "r_offset": {
        "address_offset": 0x98,
        "access": "read-write",
        "size": 32,
        "description": "R channel offset",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 12,
                "description": "R channel output offset",
            },
        },
    },
    "g_offset": {
        "address_offset": 0xa0,
        "access": "read-write",
        "size": 32,
        "description": "G channel offset",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 12,
                "description": "G channel output offset",
            },
        },
    },
    "b_offset": {
        "address_offset": 0xa8,
        "access": "read-write",
        "size": 32,
        "description": "B channel offset",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 12,
                "description": "B channel output offset",
            },
        },
    },
    "clamp_min": {
        "address_offset": 0xb0,
        "access": "read-write",
        "size": 32,
        "description": "Clamp Minimum",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 10,
                "description": "Minimum output pixel value",
            },
        },
    },
    "clip_max": {
        "address_offset": 0xb8,
        "access": "read-write",
        "size": 32,
        "description": "Clamp Maximum",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 10,
                "description": "Maximum output pixel value",
            },
        },
    },
    "k11_2": {
        "address_offset": 0xc0,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K11",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K11_2 (0x1000 = 1.0)",
            },
        },
    },
    "k12_2": {
        "address_offset": 0xc8,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K12",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K12_2 (0x1000 = 1.0)",
            },
        },
    },
    "k13_2": {
        "address_offset": 0xd0,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K13",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K13_2 (0x1000 = 1.0)",
            },
        },
    },
    "k21_2": {
        "address_offset": 0xd8,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K21",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K21_2 (0x1000 = 1.0)",
            },
        },
    },
    "k22_2": {
        "address_offset": 0xe0,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K22",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K22_2 (0x1000 = 1.0)",
            },
        },
    },
    "k23_2": {
        "address_offset": 0xe8,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K23",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K23_2 (0x1000 = 1.0)",
            },
        },
    },
    "k31_2": {
        "address_offset": 0xf0,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K31",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K31_2 (0x1000 = 1.0)",
            },
        },
    },
    "k32_2": {
        "address_offset": 0xf8,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K32",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K32_2 (0x1000 = 1.0)",
            },
        },
    },
    "k33_2": {
        "address_offset": 0x100,
        "access": "read-write",
        "size": 32,
        "description": "Color matrix 2 coefficient K33",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 16,
                "description": "Coefficient K33_2 (0x1000 = 1.0)",
            },
        },
    },
    "r_offset_2": {
        "address_offset": 0x108,
        "access": "read-write",
        "size": 32,
        "description": "R channel offset (matrix 2)",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 12,
                "description": "R channel output offset (matrix 2)",
            },
        },
    },
    "g_offset_2": {
        "address_offset": 0x110,
        "access": "read-write",
        "size": 32,
        "description": "G channel offset (matrix 2)",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 12,
                "description": "G channel output offset (matrix 2)",
            },
        },
    },
    "b_offset_2": {
        "address_offset": 0x118,
        "access": "read-write",
        "size": 32,
        "description": "B channel offset (matrix 2)",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 12,
                "description": "B channel output offset (matrix 2)",
            },
        },
    },
    "clamp_min_2": {
        "address_offset": 0x120,
        "access": "read-write",
        "size": 32,
        "description": "Clamp Minimum (matrix 2)",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 10,
                "description": "Minimum output pixel value (matrix 2)",
            },
        },
    },
    "clip_max_2": {
        "address_offset": 0x128,
        "access": "read-write",
        "size": 32,
        "description": "Clamp Maximum (matrix 2)",
        "fields": {
            "value": {
                "access": "read-write",
                "bit_offset": 0,
                "bit_width": 10,
                "description": "Maximum output pixel value (matrix 2)",
            },
        },
    },
}

_UNITY_COEFF = 0x1000


def _gain_to_coeff(gain):
    """Convert a floating point gain to a 16-bit matrix coefficient."""
    return max(0, min(round(gain * _UNITY_COEFF), 0xFFFF))


_DIAGONAL_REGS = ("k11", "k22", "k33")


_COEFF_REGS = ["k11", "k12", "k13",
               "k21", "k22", "k23",
               "k31", "k32", "k33",
               "r_offset", "g_offset", "b_offset",
               "clamp_min", "clip_max"]


class VideoProcessingCSC(DefaultIP):
    """Driver for the Xilinx Video Processing Subsystem (CSC mode).

    Implements a 3x3 color space conversion matrix with per-channel
    offsets and output clamping. Coefficients are 16-bit values where
    0x1000 represents 1.0. Offsets are 12-bit and clamp values are
    10-bit.

    """

    bindto = ["xilinx.com:ip:v_proc_ss:2.3"]

    def __init__(self, description):
        description["registers"] = _registers
        super().__init__(description)

    def configure(self, width, height, gains=(1.0, 1.0, 1.0)):
        """Configure the colour matrix and enable.

        Parameters
        ----------
        width : int
            Frame width in pixels
        height : int
            Frame height in lines
        gains : tuple of float
            Per-channel (red, green, blue) gains written to the matrix
            diagonal. The default applies no correction.
        """
        rmap = self.register_map
        rmap.in_video_format = 0x0
        rmap.out_video_format = 0x0
        self.gains = gains
        rmap.width = width
        rmap.height = height
        rmap.ap_ctrl = 0x81  # ap_start=1, auto_restart=1 in a single write

    @property
    def gains(self):
        """Per-channel (red, green, blue) gains on the matrix diagonal."""
        rmap = self.register_map
        return tuple(int(getattr(rmap, name)) / _UNITY_COEFF
                     for name in _DIAGONAL_REGS)

    @gains.setter
    def gains(self, gains):
        """Write a diagonal matrix, scaling each channel without mixing.

        Gains of 1.0 give the identity (passthrough) matrix.
        """
        gains = tuple(gains)
        if len(gains) != 3:
            raise ValueError(
                f"Expected (red, green, blue) gains, got {len(gains)} values")
        rmap = self.register_map
        for name, gain in zip(_DIAGONAL_REGS, gains):
            setattr(rmap, name, _gain_to_coeff(gain))
        rmap.k12 = 0x0
        rmap.k13 = 0x0
        rmap.k21 = 0x0
        rmap.k23 = 0x0
        rmap.k31 = 0x0
        rmap.k32 = 0x0
        rmap.r_offset = 0x0
        rmap.g_offset = 0x0
        rmap.b_offset = 0x0
        rmap.clamp_min = 0x0
        rmap.clip_max = 0xFF

    @property
    def colorspace(self):
        """Read the current 3x3 matrix + offsets + clamp as a flat list."""
        rmap = self.register_map
        return [int(getattr(rmap, name)) for name in _COEFF_REGS]

    @colorspace.setter
    def colorspace(self, matrix):
        """Write a 3x3 matrix + offsets + clamp (14 values).

        Parameters
        ----------
        matrix : list
            14 integer values: 9 matrix coefficients (K11-K33),
            3 channel offsets (R, G, B), clamp min, and clip max.
        """
        if len(matrix) != len(_COEFF_REGS):
            raise ValueError(f"Expected {len(_COEFF_REGS)} values, got "
                             f"{len(matrix)}")
        rmap = self.register_map
        for name, val in zip(_COEFF_REGS, matrix):
            setattr(rmap, name, val)
