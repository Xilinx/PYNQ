#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""Behaviour shared by the Sony sensors (IMX219, IMX708).

Both Raspberry Pi camera modules follow the SMIA-style register
convention, so streaming control, the test pattern and the orientation
flips are identical between them and differ only in which register
address they land on. Only ``REG_ORIENTATION`` actually varies today, but
the rest are declared as class attributes too so a future Sony part can
override any of them without reimplementing the methods.

Exposure and gain are deliberately *not* here: their register widths and
clamping ranges are sensor-specific, so each subclass implements its own.
"""

import time

from .camera_sensor import CameraSensor

__all__ = ["SonySensor"]


class SonySensor(CameraSensor):
    """Common implementation for Sony SMIA-style sensors.

    Subclasses must define
    ----------------------
    REG_ORIENTATION : int
        Register holding the mirror (bit 0) and flip (bit 1) controls.
    """

    #: Streaming on/off. Same address on every Sony part supported here.
    REG_MODE_SELECT = 0x0100
    #: Mirror in bit 0, vertical flip in bit 1.
    REG_ORIENTATION = None
    #: 16-bit test pattern selector.
    REG_TEST_PATTERN = 0x0600

    MODE_STANDBY = 0x00
    MODE_STREAMING = 0x01

    TEST_PATTERN_DISABLE = 0
    TEST_PATTERN_COLOR_BARS = 2

    #: Seconds to wait after leaving standby for the first frame.
    START_SETTLE = 0.05

    def __init__(self, i2c_bus, slave_addr=None):
        super().__init__(i2c_bus, slave_addr)
        #: Mode config selected by :meth:`configure`, used to clamp exposure.
        self._mode = None

    def start(self):
        """Start streaming."""
        self.write_reg(self.REG_MODE_SELECT, self.MODE_STREAMING)
        # The first frame after leaving standby is discarded by the sensor.
        time.sleep(self.START_SETTLE)

    def stop(self):
        """Put the sensor in software standby (stop streaming)."""
        self.write_reg(self.REG_MODE_SELECT, self.MODE_STANDBY)

    def test_pattern(self, enable=True):
        """Toggle the sensor's built-in colour-bar test pattern.

        Parameters
        ----------
        enable : bool
            True to emit colour bars, False for normal imaging.
        """
        self.write_reg16(
            self.REG_TEST_PATTERN,
            self.TEST_PATTERN_COLOR_BARS if enable
            else self.TEST_PATTERN_DISABLE)

    def mirror(self):
        """Toggle horizontal mirror on the sensor.

        Note this shifts the Bayer phase by one column: set
        ``bayer_phase`` on the hierarchy to keep the colours correct.
        """
        self.write_reg(self.REG_ORIENTATION,
                       self.read_reg(self.REG_ORIENTATION) ^ 0x01)

    def flip(self):
        """Toggle vertical flip on the sensor.

        Note this shifts the Bayer phase by one row: set ``bayer_phase``
        on the hierarchy to keep the colours correct.
        """
        self.write_reg(self.REG_ORIENTATION,
                       self.read_reg(self.REG_ORIENTATION) ^ 0x02)
