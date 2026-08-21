#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""Sony IMX219 driver — Raspberry Pi Camera Module v2.

Register tables are ported from the Raspberry Pi kernel driver
``drivers/media/i2c/imx219.c`` (rpi-6.6.y); the symbol each one comes
from is named above it.
"""

from .sony_sensor import SonySensor

__all__ = ["IMX219"]

# Register addresses, from imx219.c
_REG_CSI_LANE_MODE = 0x0114
_REG_DPHY_CTRL = 0x0128
_REG_EXCK_FREQ = 0x012A
_REG_ANALOG_GAIN = 0x0157
_REG_DIGITAL_GAIN = 0x0158
_REG_EXPOSURE = 0x015A
_REG_FRAME_LENGTH = 0x0160
_REG_LINE_LENGTH = 0x0162
_REG_X_ADD_STA = 0x0164
_REG_X_ADD_END = 0x0166
_REG_Y_ADD_STA = 0x0168
_REG_Y_ADD_END = 0x016A
_REG_X_OUTPUT_SIZE = 0x016C
_REG_Y_OUTPUT_SIZE = 0x016E
_REG_BINNING_MODE = 0x0174
_REG_CSI_DATA_FORMAT = 0x018C
_REG_OPPXCK_DIV = 0x0309
_REG_TP_WINDOW_WIDTH = 0x0624
_REG_TP_WINDOW_HEIGHT = 0x0626


_BINNING_NONE = 0x0000
# IMX219_BINNING_2X2_NORMAL. The 0x0303 "special" variant is what the
# kernel picks for RAW8 only; at RAW10 it uses normal binning, and
# special binning additionally halves exposure and frame length
# (rate_factor in imx219.c).
_BINNING_2X2 = 0x0101


# Fixed for every 2-lane mode, so frame rate is set by frame length alone.
# From IMX219_PIXEL_RATE and LINE_LENGTH_A in imx219.c.
_PIXEL_RATE = 182400000
_LINE_LENGTH = 3448
_LINES_PER_SECOND = _PIXEL_RATE // _LINE_LENGTH

# Active pixel array, from IMX219_PIXEL_ARRAY_* in imx219.c
_ARRAY_WIDTH = 3280
_ARRAY_HEIGHT = 2464

# Ported from imx219_common_regs in imx219.c. Applies to every mode.
_CFG_COMMON = (
    (0x0100, 0x00),                     # standby while reconfiguring

    # To access addresses 3000-5fff, send the following commands
    (0x30EB, 0x05),
    (0x30EB, 0x0C),
    (0x300A, 0xFF),
    (0x300B, 0xFF),
    (0x30EB, 0x05),
    (0x30EB, 0x09),

    # Undocumented registers
    (0x455E, 0x00),
    (0x471E, 0x4B),
    (0x4767, 0x0F),
    (0x4750, 0x14),
    (0x4540, 0x00),
    (0x47B4, 0x14),
    (0x4713, 0x30),
    (0x478B, 0x10),
    (0x478F, 0x10),
    (0x4793, 0x10),
    (0x4797, 0x0E),
    (0x479B, 0x0E),

    # Frame bank register group "A"
    (_REG_LINE_LENGTH, _LINE_LENGTH >> 8),
    (_REG_LINE_LENGTH + 1, _LINE_LENGTH & 0xFF),
    (0x0170, 0x01),                     # X_ODD_INC_A
    (0x0171, 0x01),                     # Y_ODD_INC_A

    # Output setup: automatic D-PHY timing, 24 MHz external clock
    (_REG_DPHY_CTRL, 0x00),
    (_REG_EXCK_FREQ, 24),               # EXCK_FREQ = MHz * 256, big-endian
    (_REG_EXCK_FREQ + 1, 0x00),
)

# Ported from imx219_2lane_regs in imx219.c. The PCB routes 2 lanes.
_CFG_2LANE = (
    (0x0301, 5),                        # VTPXCK_DIV
    (0x0303, 1),                        # VTSYCK_DIV
    (0x0304, 3),                        # PREPLLCK_VT_DIV, 0x03 = AUTO
    (0x0305, 3),                        # PREPLLCK_OP_DIV, 0x03 = AUTO
    (0x0306, 0), (0x0307, 57),          # PLL_VT_MPY = 57
    (0x030B, 1),                        # OPSYCK_DIV
    (0x030C, 0), (0x030D, 114),         # PLL_OP_MPY = 114
    (_REG_CSI_LANE_MODE, 0x01),         # 2-lane CSI mode
)

# Ported from raw10_framefmt_regs in imx219.c. The pipeline is RAW10 only.
_CFG_RAW10 = (
    (_REG_CSI_DATA_FORMAT, 0x0A),
    (_REG_CSI_DATA_FORMAT + 1, 0x0A),
    (_REG_OPPXCK_DIV, 10),
)


def _centred_crop(out_width, out_height, binning):
    """Derive a centred readout window for an output size.

    Binned modes read the whole array and let the binning do the
    downscale, matching mode_1640_1232_regs in imx219.c; cropping *and*
    binning is not a combination the kernel driver ever programs.
    Unbinned modes take a centred window, as mode_1920_1080_regs does.
    Offsets are forced even to keep the Bayer phase (RGGB) unchanged.
    """
    if binning:
        return 0, 0, _ARRAY_WIDTH, _ARRAY_HEIGHT
    left = ((_ARRAY_WIDTH - out_width) // 2) & ~1
    top = ((_ARRAY_HEIGHT - out_height) // 2) & ~1
    return left, top, out_width, out_height


class _Mode:
    """One supported sensor mode."""

    def __init__(self, width, height, fps, binning):
        self.width = width
        self.height = height
        self.fps = fps
        self.binning = binning
        self.left, self.top, self.crop_w, self.crop_h = _centred_crop(
            width, height, binning)
        self.frame_length = _LINES_PER_SECOND // fps

    def registers(self):
        """The mode-specific register writes, in programming order."""
        binning = _BINNING_2X2 if self.binning else _BINNING_NONE
        return (
            (_REG_X_ADD_STA, self.left >> 8),
            (_REG_X_ADD_STA + 1, self.left & 0xFF),
            (_REG_X_ADD_END, (self.left + self.crop_w - 1) >> 8),
            (_REG_X_ADD_END + 1, (self.left + self.crop_w - 1) & 0xFF),
            (_REG_Y_ADD_STA, self.top >> 8),
            (_REG_Y_ADD_STA + 1, self.top & 0xFF),
            (_REG_Y_ADD_END, (self.top + self.crop_h - 1) >> 8),
            (_REG_Y_ADD_END + 1, (self.top + self.crop_h - 1) & 0xFF),
            (_REG_BINNING_MODE, binning >> 8),
            (_REG_BINNING_MODE + 1, binning & 0xFF),
            (_REG_X_OUTPUT_SIZE, self.width >> 8),
            (_REG_X_OUTPUT_SIZE + 1, self.width & 0xFF),
            (_REG_Y_OUTPUT_SIZE, self.height >> 8),
            (_REG_Y_OUTPUT_SIZE + 1, self.height & 0xFF),
            (_REG_TP_WINDOW_WIDTH, self.width >> 8),
            (_REG_TP_WINDOW_WIDTH + 1, self.width & 0xFF),
            (_REG_TP_WINDOW_HEIGHT, self.height >> 8),
            (_REG_TP_WINDOW_HEIGHT + 1, self.height & 0xFF),
            (_REG_FRAME_LENGTH, self.frame_length >> 8),
            (_REG_FRAME_LENGTH + 1, self.frame_length & 0xFF),
        )


# 720p is the 2x2-binned mode (Raspberry Pi "mode 6"); 1080p is a native
# crop of the array (Raspberry Pi "mode 1"), matching mode_1920_1080_regs.
_MODE_CONFIGS = {
    0: _Mode(1280, 720, 60, binning=True),
    1: _Mode(1920, 1080, 30, binning=False),
}

# From IMX219_EXPOSURE_OFFSET in imx219.c; exposure must leave room for
# the frame's blanking.
_EXPOSURE_OFFSET = 4
# IMX219_EXPOSURE_MIN
_EXPOSURE_MIN = 4

# From IMX219_ANA_GAIN_* / IMX219_DGTL_GAIN_* in imx219.c
_ANA_GAIN_MAX = 232
_DGTL_GAIN_MIN = 0x0100
_DGTL_GAIN_MAX = 0x0FFF

# 6.4x, from 256 / (256 - 216).
_DEFAULT_GAIN = 216


class IMX219(SonySensor):
    """Sony IMX219 sensor driver (Raspberry Pi Camera Module v2).

    There is no auto-exposure loop: exposure and gain are set to fixed
    defaults sized for the selected mode and can be adjusted afterwards
    with :attr:`exposure` and :attr:`gain`.

    Parameters
    ----------
    i2c_bus : int
        Linux I2C bus number
    slave_addr : int
        I2C slave address of the sensor (default 0x10)
    """

    NAME = "IMX219"
    I2C_ADDR = 0x10
    ID_REG = 0x0000
    ID_VALUE = 0x0219
    # 456 MHz link => 912 Mbps/lane DDR, what the D-PHY is built for.
    HS_SETTLE_NS = 124
    # imx219_mbus_formats[0] (no flip) is SRGGB10.
    BAYER_PHASE = 0x0
    # Grey-world measurement under one indoor illuminant, no grey card:
    # a starting point, not a calibration. Normalised so the largest is
    # 1.0, as there is no AE loop to pull back a gain that clips.
    WB_GAINS = (0.799, 0.541, 1.0)
    # Raw output is scene-linear; 2.2 approximates sRGB for display.
    GAMMA = 2.2
    # 4096/65535 in libcamera's imx219.json, i.e. 64 in the native 10
    # bits. Confirmed by fitting mean against analogue gain.
    BLACK_LEVEL = 16
    MODES = {
        (1280, 720, 60): 0,
        (1920, 1080, 30): 1,
    }
    # Accepts back-to-back writes; a per-write delay would cost seconds.
    REG_DELAY = 0
    #: Mirror/flip control register for this part.
    REG_ORIENTATION = 0x0172

    def configure(self, mode, gpio_ip, power_cycle=True):
        """Full sensor initialization sequence.

        Parameters
        ----------
        mode : int
            Mode id (0=720p60, 1=1080p30)
        gpio_ip : DefaultIP
            GPIO IP for camera power control
        power_cycle : bool
            Whether to power-cycle the sensor first.
        """
        if mode not in _MODE_CONFIGS:
            raise ValueError(f"Invalid mode {mode}, must be one of "
                             f"{list(_MODE_CONFIGS.keys())}")
        if power_cycle:
            self.power_cycle(gpio_ip)
        self.verify_sensor_id()

        cfg = _MODE_CONFIGS[mode]
        self._mode = cfg

        self.stop()
        self._write_config(_CFG_COMMON)
        self._write_config(_CFG_2LANE)
        self._write_config(_CFG_RAW10)
        self._write_config(cfg.registers())

        # No AE loop, so pick a starting point for a typical indoor
        # scene. Measured indoors this lands the mean near 120 of 255.
        self.exposure = int(cfg.frame_length * 0.9) - _EXPOSURE_OFFSET
        self.gain = _DEFAULT_GAIN
        self.digital_gain = _DGTL_GAIN_MIN

    @property
    def exposure(self):
        """Exposure time in lines, clamped to the frame length less
        the blanking the sensor needs."""
        return self.read_reg16(_REG_EXPOSURE)

    @exposure.setter
    def exposure(self, lines):
        if self._mode is None:
            raise RuntimeError("configure() the sensor first")
        limit = self._mode.frame_length - _EXPOSURE_OFFSET
        self.write_reg16(_REG_EXPOSURE, max(_EXPOSURE_MIN, min(lines, limit)))

    @property
    def gain(self):
        """Analogue gain code, 0-232: the gain is 256 / (256 - code),
        so 0 is 1x and 232 is about 10.7x."""
        return self.read_reg(_REG_ANALOG_GAIN)

    @gain.setter
    def gain(self, code):
        self.write_reg(_REG_ANALOG_GAIN, max(0, min(code, _ANA_GAIN_MAX)))

    @property
    def digital_gain(self):
        """Digital gain in 1/256ths, 0x0100 (1x) to 0x0FFF."""
        return self.read_reg16(_REG_DIGITAL_GAIN)

    @digital_gain.setter
    def digital_gain(self, value):
        self.write_reg16(_REG_DIGITAL_GAIN,
                         max(_DGTL_GAIN_MIN, min(value, _DGTL_GAIN_MAX)))

