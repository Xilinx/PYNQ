#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import time

from .camera_sensor import CameraSensor

__all__ = ["OV5640"]

# Register tables ported from pcam_5c.h; entries are (address, data).

_CFG_INIT = (
    (0x3008, 0x42),
    (0x3103, 0x03),
    (0x3017, 0x00),
    (0x3018, 0x00),
    (0x3034, 0x18),
    (0x3035, 0x11),
    (0x3036, 0x38),
    (0x3037, 0x11),
    (0x3108, 0x01),
    (0x303D, 0x10),
    (0x303B, 0x19),
    (0x3630, 0x2e),
    (0x3631, 0x0e),
    (0x3632, 0xe2),
    (0x3633, 0x23),
    (0x3621, 0xe0),
    (0x3704, 0xa0),
    (0x3703, 0x5a),
    (0x3715, 0x78),
    (0x3717, 0x01),
    (0x370b, 0x60),
    (0x3705, 0x1a),
    (0x3905, 0x02),
    (0x3906, 0x10),
    (0x3901, 0x0a),
    (0x3731, 0x02),
    (0x3600, 0x37),
    (0x3601, 0x33),
    (0x302d, 0x60),
    (0x3620, 0x52),
    (0x371b, 0x20),
    (0x471c, 0x50),
    (0x3a13, 0x43),
    (0x3a18, 0x00),
    (0x3a19, 0xf8),
    (0x3635, 0x13),
    (0x3636, 0x06),
    (0x3634, 0x44),
    (0x3622, 0x01),
    (0x3c01, 0x34),
    (0x3c04, 0x28),
    (0x3c05, 0x98),
    (0x3c06, 0x00),
    (0x3c07, 0x08),
    (0x3c08, 0x00),
    (0x3c09, 0x1c),
    (0x3c0a, 0x9c),
    (0x3c0b, 0x40),
    (0x503d, 0x00),
    (0x3820, 0x46),
    (0x300e, 0x45),
    (0x4800, 0x14),
    (0x302e, 0x08),
    (0x4300, 0x6f),
    (0x501f, 0x01),
    (0x4713, 0x03),
    (0x4407, 0x04),
    (0x440e, 0x00),
    (0x460b, 0x35),
    (0x460c, 0x20),
    (0x3824, 0x01),
    (0x5000, 0x07),
    (0x5001, 0x03),
)

_CFG_720P_60FPS = (
    (0x3035, 0x21),
    (0x3036, 0x46),
    (0x3037, 0x05),
    (0x3108, 0x11),
    (0x3034, 0x1A),
    (0x3800, 0x00),
    (0x3801, 0x00),
    (0x3802, 0x00),
    (0x3803, 0x08),
    (0x3804, 0x0A),
    (0x3805, 0x3B),
    (0x3806, 0x07),
    (0x3807, 0x9B),
    (0x3810, 0x00),
    (0x3811, 0x00),
    (0x3812, 0x00),
    (0x3813, 0x00),
    (0x3808, 0x05),
    (0x3809, 0x00),
    (0x380a, 0x02),
    (0x380b, 0xD0),
    (0x380c, 0x07),
    (0x380d, 0x68),
    (0x380e, 0x03),
    (0x380f, 0xD8),
    (0x3814, 0x31),
    (0x3815, 0x31),
    (0x3821, 0x01),
    (0x4837, 36),
    (0x3618, 0x00),
    (0x3612, 0x59),
    (0x3708, 0x64),
    (0x3709, 0x52),
    (0x370c, 0x03),
    (0x4300, 0x00),
    (0x501f, 0x03),
)

_CFG_1080P_15FPS = (
    (0x3035, 0x41),
    (0x3036, 0x69),
    (0x3037, 0x05),
    (0x3108, 0x11),
    (0x3034, 0x1A),
    (0x3800, 0x01),
    (0x3801, 0x50),
    (0x3802, 0x01),
    (0x3803, 0xAA),
    (0x3804, 0x08),
    (0x3805, 0xEF),
    (0x3806, 0x05),
    (0x3807, 0xF9),
    (0x3810, 0x00),
    (0x3811, 0x10),
    (0x3812, 0x00),
    (0x3813, 0x0C),
    (0x3808, 0x07),
    (0x3809, 0x80),
    (0x380a, 0x04),
    (0x380b, 0x38),
    (0x380c, 0x09),
    (0x380d, 0xC4),
    (0x380e, 0x04),
    (0x380f, 0x60),
    (0x3814, 0x11),
    (0x3815, 0x11),
    (0x3821, 0x00),
    (0x4837, 48),
    (0x3618, 0x00),
    (0x3612, 0x59),
    (0x3708, 0x64),
    (0x3709, 0x52),
    (0x370c, 0x03),
    (0x4300, 0x00),
    (0x501f, 0x03),
)

_CFG_1080P_30FPS = (
    (0x3035, 0x21),
    (0x3036, 0x69),
    (0x3037, 0x05),
    (0x3108, 0x11),
    (0x3034, 0x1A),
    (0x3800, 0x01),
    (0x3801, 0x50),
    (0x3802, 0x01),
    (0x3803, 0xAA),
    (0x3804, 0x08),
    (0x3805, 0xEF),
    (0x3806, 0x05),
    (0x3807, 0xF9),
    (0x3810, 0x00),
    (0x3811, 0x10),
    (0x3812, 0x00),
    (0x3813, 0x0C),
    (0x3808, 0x07),
    (0x3809, 0x80),
    (0x380a, 0x04),
    (0x380b, 0x38),
    (0x380c, 0x09),
    (0x380d, 0xC4),
    (0x380e, 0x04),
    (0x380f, 0x60),
    (0x3814, 0x11),
    (0x3815, 0x11),
    (0x3821, 0x00),
    (0x4837, 24),
    (0x3618, 0x00),
    (0x3612, 0x59),
    (0x3708, 0x64),
    (0x3709, 0x52),
    (0x370c, 0x03),
    (0x4300, 0x00),
    (0x501f, 0x03),
)

_CFG_ADVANCED_AWB = (
    (0x3406, 0x00),
    (0x5192, 0x04),
    (0x5191, 0xf8),
    (0x518d, 0x26),
    (0x518f, 0x42),
    (0x518e, 0x2b),
    (0x5190, 0x42),
    (0x518b, 0xd0),
    (0x518c, 0xbd),
    (0x5187, 0x18),
    (0x5188, 0x18),
    (0x5189, 0x56),
    (0x518a, 0x5c),
    (0x5186, 0x1c),
    (0x5181, 0x50),
    (0x5184, 0x20),
    (0x5182, 0x11),
    (0x5183, 0x00),
    (0x5001, 0x03),
)

_CFG_SIMPLE_AWB = (
    (0x518d, 0x00),
    (0x518f, 0x20),
    (0x518e, 0x00),
    (0x5190, 0x20),
    (0x518b, 0x00),
    (0x518c, 0x00),
    (0x5187, 0x10),
    (0x5188, 0x10),
    (0x5189, 0x40),
    (0x518a, 0x40),
    (0x5186, 0x10),
    (0x5181, 0x58),
    (0x5184, 0x25),
    (0x5182, 0x11),
    (0x3406, 0x00),
    (0x5183, 0x80),
    (0x5191, 0xff),
    (0x5192, 0x00),
    (0x5001, 0x03),
)

_CFG_DISABLE_AWB = (
    (0x5001, 0x02),
)

_MODE_CONFIGS = {
    0: _CFG_720P_60FPS,
    1: _CFG_1080P_30FPS,
    2: _CFG_1080P_15FPS,
}

_AWB_CONFIGS = {
    'advanced': _CFG_ADVANCED_AWB,
    'simple': _CFG_SIMPLE_AWB,
    'disabled': _CFG_DISABLE_AWB,
}


class OV5640(CameraSensor):
    """OV5640 MIPI camera sensor driver (Digilent Pcam 5C).

    Parameters
    ----------
    i2c_bus : int
        Linux I2C bus number (e.g. 6 for /dev/i2c-6)
    slave_addr : int
        I2C slave address of the sensor (default 0x3C)
    """

    NAME = "OV5640"
    I2C_ADDR = 0x3C
    ID_REG = 0x300A
    ID_VALUE = 0x5640
    HS_SETTLE_NS = 149
    # BGGR: _CFG_INIT sets the flip bits in 0x3820, shifting the Bayer
    # grid by a row. Confirmed by a phase sweep.
    BAYER_PHASE = 0x3
    MODES = {
        (1280, 720, 60): 0,
        (1920, 1080, 30): 1,
        (1920, 1080, 15): 2,
    }

    def __init__(self, i2c_bus, slave_addr=None):
        super().__init__(i2c_bus, slave_addr)
        self._awb = None

    def configure(self, mode, gpio_ip, power_cycle=True, reset_settle=1.0):
        """Full sensor initialization sequence.

        Power-cycles the sensor, verifies the ID, writes the base
        initialization table, applies the mode-specific config,
        and writes AWB settings.

        Parameters
        ----------
        mode : int
            Video mode index (0=720p60, 1=1080p30, 2=1080p15)
        gpio_ip : DefaultIP
            GPIO IP for camera power control
        power_cycle : bool
            Whether to power-cycle the sensor first. Skipped when the
            caller has already powered the camera up, as the hierarchy
            driver does before identifying it over I2C.
        reset_settle : float
            Seconds to wait after the software reset for XVCLK and the
            sensor PLL to stabilize before writing the config. The
            default matches Digilent's reference driver.
        """
        if mode not in _MODE_CONFIGS:
            raise ValueError(f"Invalid mode {mode}, must be one of "
                             f"{list(_MODE_CONFIGS.keys())}")
        if power_cycle:
            self.power_cycle(gpio_ip)
        self.verify_sensor_id()

        self.write_reg(0x3103, 0x11)
        self.write_reg(0x3008, 0x82)
        time.sleep(reset_settle)

        self._write_config(_CFG_INIT)

        self.write_reg(0x3008, 0x42)
        self._write_config(_MODE_CONFIGS[mode])

        # Wake sensor, then power down for AWB config
        self.write_reg(0x3008, 0x02)
        time.sleep(0.01)
        self.write_reg(0x3008, 0x42)
        self.awb = 'advanced'

    def start(self):
        """Wake the sensor and start streaming."""
        self.write_reg(0x3008, 0x02)

    def stop(self):
        """Power down the sensor (stop streaming)."""
        self.write_reg(0x3008, 0x42)

    def test_pattern(self, enable=True):
        """Enable or disable the sensor's built-in color-bar test pattern.

        Writes reg 0x503d bit7 (color-bar enable). The pattern is
        generated inside the sensor and streamed over MIPI independently
        of the imaging pipeline, so it isolates the MIPI/D-PHY/VDMA
        transport from sensor imaging/AWB/exposure configuration.

        Parameters
        ----------
        enable : bool
            True to emit color bars, False for normal imaging.
        """
        current = self.read_reg(0x503d)
        if enable:
            self.write_reg(0x503d, current | 0x80)
        else:
            self.write_reg(0x503d, current & ~0x80)

    def mirror(self):
        """Toggle horizontal mirror on the sensor."""
        current = self.read_reg(0x3821)
        self.write_reg(0x3821, current ^ 0x06)

    def flip(self):
        """Toggle vertical flip on the sensor."""
        current = self.read_reg(0x3820)
        self.write_reg(0x3820, current ^ 0x06)

    @property
    def awb(self):
        """Auto white balance mode: 'advanced', 'simple' or 'disabled'.

        Reports the last mode written, as the sensor cannot read it
        back. None until :meth:`configure` has run.
        """
        return self._awb

    @awb.setter
    def awb(self, mode):
        if mode not in _AWB_CONFIGS:
            raise ValueError(f"Invalid AWB mode '{mode}', must be one of "
                             f"{list(_AWB_CONFIGS.keys())}")
        self._write_config(_AWB_CONFIGS[mode])
        self._awb = mode
