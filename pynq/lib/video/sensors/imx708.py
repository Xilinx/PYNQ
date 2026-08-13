#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""Sony IMX708 driver — Raspberry Pi Camera Module v3.

Register tables are ported verbatim from the Raspberry Pi kernel driver
``drivers/media/i2c/imx708.c`` (rpi-6.6.y); the symbol each one comes from
is named above it.

The driver's binned modes are 1536x864 and 2304x1296 — neither is 720p nor
1080p. Rather than retune the analogue readout, each kernel mode is kept
exactly as validated and the sensor's digital crop (``DIG_CROP_*``) takes a
centred 1280x720 or 1920x1080 window out of it, so the field of view is a
little narrower than the full binned mode.

The module is fixed-focus: the DW9817 VCM sits at its own I2C address
(0x0C) and is left at its power-on position.
"""

from .sony_sensor import SonySensor

__all__ = ["IMX708"]

# Register addresses, from imx708.c
_REG_EXPOSURE = 0x0202
_REG_ANALOG_GAIN = 0x0204
_REG_DIGITAL_GAIN = 0x020E
_REG_FRAME_LENGTH = 0x0340
# LINE_LENGTH (0x0342) is set by the verbatim mode tables, not written here.
_REG_DIG_CROP_X_OFFSET = 0x0408
_REG_DIG_CROP_Y_OFFSET = 0x040A
_REG_DIG_CROP_WIDTH = 0x040C
_REG_DIG_CROP_HEIGHT = 0x040E
_REG_X_OUTPUT_SIZE = 0x034C
_REG_Y_OUTPUT_SIZE = 0x034E
_REG_BASE_SPC_GAINS_L = 0x7B10
_REG_BASE_SPC_GAINS_R = 0x7C00
_REG_LPF_INTENSITY_EN = 0xC428

_LPF_INTENSITY_DISABLED = 0x01

# Gain limits, from IMX708_ANA_GAIN_* / IMX708_DGTL_GAIN_* in imx708.c
_ANA_GAIN_MIN = 112
_ANA_GAIN_MAX = 960
_DGTL_GAIN_MIN = 0x0100
_DGTL_GAIN_MAX = 0xFFFF

# From IMX708_EXPOSURE_OFFSET in imx708.c; exposure must leave room for
# the frame's blanking.
_EXPOSURE_OFFSET = 48
# supported_modes_10bit_no_hdr: both binned modes.
_EXPOSURE_MIN = 4
_EXPOSURE_STEP = 2

# Ported from mode_common_regs in imx708.c. Written once per power cycle.
_CFG_COMMON = (
    (0x0100, 0x00),
    (0x0136, 0x18), (0x0137, 0x00),     # INCK = 24.00 MHz
    (0x33F0, 0x02), (0x33F1, 0x05),
    (0x3062, 0x00), (0x3063, 0x12),
    (0x3068, 0x00), (0x3069, 0x12),
    (0x306A, 0x00), (0x306B, 0x30),
    (0x3076, 0x00), (0x3077, 0x30),
    (0x3078, 0x00), (0x3079, 0x30),
    (0x5E54, 0x0C),
    (0x6E44, 0x00),
    (0xB0B6, 0x01),
    (0xE829, 0x00),
    (0xF001, 0x08), (0xF003, 0x08),
    (0xF00D, 0x10), (0xF00F, 0x10),
    (0xF031, 0x08), (0xF033, 0x08),
    (0xF03D, 0x10), (0xF03F, 0x10),
    (0x0112, 0x0A), (0x0113, 0x0A),     # RAW10 in / RAW10 out
    (0x0114, 0x01),                     # 2-lane CSI mode
    (0x0B8E, 0x01), (0x0B8F, 0x00),
    (0x0B94, 0x01), (0x0B95, 0x00),
    (0x3400, 0x01),
    (0x3478, 0x01), (0x3479, 0x1C),
    (0x3091, 0x01), (0x3092, 0x00),
    (0x3419, 0x00),
    (0xBCF1, 0x02),
    (0x3094, 0x01), (0x3095, 0x01),
    (0x3362, 0x00), (0x3363, 0x00),
    (0x3364, 0x00), (0x3365, 0x00),
    (0x0138, 0x01),
)

# Ported from link_450Mhz_regs in imx708.c. 450 MHz is the nominal link
# frequency and the one the D-PHY build targets.
_CFG_LINK_450MHZ = (
    (0x030E, 0x01),
    (0x030F, 0x2C),
)

# Ported from pdaf_gains in imx708.c. Phase-detect pixel shading
# correction, applied only to uncalibrated sensors.
_PDAF_GAINS = (
    (0x4C, 0x4C, 0x4C, 0x46, 0x3E, 0x38, 0x35, 0x35, 0x35),
    (0x35, 0x35, 0x35, 0x38, 0x3E, 0x46, 0x4C, 0x4C, 0x4C),
)

# Ported verbatim from mode_2x2binned_720p_regs in imx708.c.
# 3072x1728 readout, 2x2 binned to 1536x864.
_CFG_2X2BINNED_720P = (
    (0x0342, 0x14), (0x0343, 0x60),
    (0x0340, 0x04), (0x0341, 0xB6),
    (0x0344, 0x03), (0x0345, 0x00),
    (0x0346, 0x01), (0x0347, 0xB0),
    (0x0348, 0x0E), (0x0349, 0xFF),
    (0x034A, 0x08), (0x034B, 0x6F),
    (0x0220, 0x62),
    (0x0222, 0x01),
    (0x0900, 0x01), (0x0901, 0x22), (0x0902, 0x08),
    (0x3200, 0x41), (0x3201, 0x41),
    (0x32D5, 0x00), (0x32D6, 0x00),
    (0x32DB, 0x01), (0x32DF, 0x01),
    (0x350C, 0x00), (0x350D, 0x00),
    (0x0408, 0x00), (0x0409, 0x00),
    (0x040A, 0x00), (0x040B, 0x00),
    (0x040C, 0x06), (0x040D, 0x00),
    (0x040E, 0x03), (0x040F, 0x60),
    (0x034C, 0x06), (0x034D, 0x00),
    (0x034E, 0x03), (0x034F, 0x60),
    (0x0301, 0x05),
    (0x0303, 0x02),
    (0x0305, 0x02),
    (0x0306, 0x00), (0x0307, 0x76),
    (0x030B, 0x02),
    (0x030D, 0x04),
    (0x0310, 0x01),
    (0x3CA0, 0x00), (0x3CA1, 0x3C),
    (0x3CA4, 0x01), (0x3CA5, 0x5E),
    (0x3CA6, 0x00), (0x3CA7, 0x00),
    (0x3CAA, 0x00), (0x3CAB, 0x00),
    (0x3CB8, 0x00), (0x3CB9, 0x0C),
    (0x3CBA, 0x00), (0x3CBB, 0x04),
    (0x3CBC, 0x00), (0x3CBD, 0x1E),
    (0x3CBE, 0x00), (0x3CBF, 0x05),
    (0x0202, 0x04), (0x0203, 0x86),
    (0x0224, 0x01), (0x0225, 0xF4),
    (0x3116, 0x01), (0x3117, 0xF4),
    (0x0204, 0x00), (0x0205, 0x70),
    (0x0216, 0x00), (0x0217, 0x70),
    (0x0218, 0x01), (0x0219, 0x00),
    (0x020E, 0x01), (0x020F, 0x00),
    (0x3118, 0x00), (0x3119, 0x70),
    (0x311A, 0x01), (0x311B, 0x00),
    (0x341A, 0x00), (0x341B, 0x00),
    (0x341C, 0x00), (0x341D, 0x00),
    (0x341E, 0x00), (0x341F, 0x60),
    (0x3420, 0x00), (0x3421, 0x48),
    (0x3366, 0x00), (0x3367, 0x00),
    (0x3368, 0x00), (0x3369, 0x00),
)

# Ported verbatim from mode_2x2binned_regs in imx708.c.
# Full 4608x2592 readout, 2x2 binned to 2304x1296.
_CFG_2X2BINNED = (
    (0x0342, 0x1E), (0x0343, 0x90),
    (0x0340, 0x05), (0x0341, 0x38),
    (0x0344, 0x00), (0x0345, 0x00),
    (0x0346, 0x00), (0x0347, 0x00),
    (0x0348, 0x11), (0x0349, 0xFF),
    (0x034A, 0x0A), (0x034B, 0x1F),
    (0x0220, 0x62),
    (0x0222, 0x01),
    (0x0900, 0x01), (0x0901, 0x22), (0x0902, 0x08),
    (0x3200, 0x41), (0x3201, 0x41),
    (0x32D5, 0x00), (0x32D6, 0x00),
    (0x32DB, 0x01), (0x32DF, 0x00),
    (0x350C, 0x00), (0x350D, 0x00),
    (0x0408, 0x00), (0x0409, 0x00),
    (0x040A, 0x00), (0x040B, 0x00),
    (0x040C, 0x09), (0x040D, 0x00),
    (0x040E, 0x05), (0x040F, 0x10),
    (0x034C, 0x09), (0x034D, 0x00),
    (0x034E, 0x05), (0x034F, 0x10),
    (0x0301, 0x05),
    (0x0303, 0x02),
    (0x0305, 0x02),
    (0x0306, 0x00), (0x0307, 0x7A),
    (0x030B, 0x02),
    (0x030D, 0x04),
    (0x0310, 0x01),
    (0x3CA0, 0x00), (0x3CA1, 0x3C),
    (0x3CA4, 0x00), (0x3CA5, 0x3C),
    (0x3CA6, 0x00), (0x3CA7, 0x00),
    (0x3CAA, 0x00), (0x3CAB, 0x00),
    (0x3CB8, 0x00), (0x3CB9, 0x1C),
    (0x3CBA, 0x00), (0x3CBB, 0x08),
    (0x3CBC, 0x00), (0x3CBD, 0x1E),
    (0x3CBE, 0x00), (0x3CBF, 0x0A),
    (0x0202, 0x05), (0x0203, 0x08),
    (0x0224, 0x01), (0x0225, 0xF4),
    (0x3116, 0x01), (0x3117, 0xF4),
    (0x0204, 0x00), (0x0205, 0x70),
    (0x0216, 0x00), (0x0217, 0x70),
    (0x0218, 0x01), (0x0219, 0x00),
    (0x020E, 0x01), (0x020F, 0x00),
    (0x3118, 0x00), (0x3119, 0x70),
    (0x311A, 0x01), (0x311B, 0x00),
    (0x341A, 0x00), (0x341B, 0x00),
    (0x341C, 0x00), (0x341D, 0x00),
    (0x341E, 0x00), (0x341F, 0x90),
    (0x3420, 0x00), (0x3421, 0x6C),
    (0x3366, 0x00), (0x3367, 0x00),
    (0x3368, 0x00), (0x3369, 0x00),
)


class _Mode:
    """A kernel mode plus the digital crop that trims it to our output.

    ``binned_width``/``binned_height`` are the mode's own output size, from
    which a centred ``width`` x ``height`` window is taken. Offsets are
    forced even so the Bayer phase is unchanged by the crop.
    """

    def __init__(self, regs, binned_width, binned_height, width, height, fps,
                 pixel_rate, line_length):
        self.regs = regs
        self.width = width
        self.height = height
        self.fps = fps
        self.x_offset = ((binned_width - width) // 2) & ~1
        self.y_offset = ((binned_height - height) // 2) & ~1
        self.frame_length = pixel_rate // (line_length * fps)

    def crop_registers(self):
        """Digital crop and output size overriding the mode defaults."""
        return (
            (_REG_DIG_CROP_X_OFFSET, self.x_offset >> 8),
            (_REG_DIG_CROP_X_OFFSET + 1, self.x_offset & 0xFF),
            (_REG_DIG_CROP_Y_OFFSET, self.y_offset >> 8),
            (_REG_DIG_CROP_Y_OFFSET + 1, self.y_offset & 0xFF),
            (_REG_DIG_CROP_WIDTH, self.width >> 8),
            (_REG_DIG_CROP_WIDTH + 1, self.width & 0xFF),
            (_REG_DIG_CROP_HEIGHT, self.height >> 8),
            (_REG_DIG_CROP_HEIGHT + 1, self.height & 0xFF),
            (_REG_X_OUTPUT_SIZE, self.width >> 8),
            (_REG_X_OUTPUT_SIZE + 1, self.width & 0xFF),
            (_REG_Y_OUTPUT_SIZE, self.height >> 8),
            (_REG_Y_OUTPUT_SIZE + 1, self.height & 0xFF),
            (_REG_FRAME_LENGTH, self.frame_length >> 8),
            (_REG_FRAME_LENGTH + 1, self.frame_length & 0xFF),
        )


# pixel_rate and line_length_pix come from the matching entries in
# supported_modes_10bit_no_hdr in imx708.c.
_MODE_CONFIGS = {
    0: _Mode(_CFG_2X2BINNED_720P, 1536, 864, 1280, 720, 60,
             pixel_rate=566400000, line_length=0x1460),
    1: _Mode(_CFG_2X2BINNED, 2304, 1296, 1920, 1080, 30,
             pixel_rate=585600000, line_length=0x1E90),
}


class IMX708(SonySensor):
    """Sony IMX708 sensor driver (Raspberry Pi Camera Module v3).

    Fixed-focus: the voice-coil lens actuator is a separate I2C device and
    is not driven, so the lens stays wherever it powers up.

    There is no auto-exposure loop: exposure and gain are set to fixed
    defaults sized for the selected mode and can be adjusted afterwards
    with :meth:`set_exposure` and :meth:`set_gain`.

    Parameters
    ----------
    i2c_bus : int
        Linux I2C bus number
    slave_addr : int
        I2C slave address of the sensor (default 0x1A)
    """

    NAME = "IMX708"
    I2C_ADDR = 0x1A
    ID_REG = 0x0016
    ID_VALUE = 0x0708
    # 450 MHz link => 900 Mbps/lane DDR, under the 912 Mbps build.
    HS_SETTLE_NS = 124
    # codes[0] (no flip) in imx708.c is SRGGB10.
    BAYER_PHASE = 0x0
    # Daylight starting point, not a calibrated matrix.
    WB_GAINS = (1.8, 1.0, 1.6)
    MODES = {
        (1280, 720, 60): 0,
        (1920, 1080, 30): 1,
    }
    # Accepts back-to-back writes; a per-write delay would cost seconds.
    REG_DELAY = 0
    #: Mirror/flip control register for this part.
    REG_ORIENTATION = 0x0101

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
        self._write_pdaf_gains()
        self._write_config(cfg.regs)
        self._write_config(_CFG_LINK_450MHZ)
        self._write_config(cfg.crop_registers())
        # Quad-Bayer re-mosaic correction applies to the full-resolution
        # mode only, and neither mode here uses it.
        self.write_reg(_REG_LPF_INTENSITY_EN, _LPF_INTENSITY_DISABLED)

        # No AE loop, so pick a mid-scale starting point: expose for most
        # of the frame and apply a modest analogue gain.
        self.set_exposure(int(cfg.frame_length * 0.9) - _EXPOSURE_OFFSET)
        self.set_gain(_ANA_GAIN_MIN * 3)

    def _write_pdaf_gains(self):
        """Apply PDAF shading gains if the sensor is uncalibrated.

        Mirrors imx708_start_streaming: the gains are only written when
        the sensor reports the 0x40 default, meaning it carries no
        calibration of its own.
        """
        if self.read_reg(_REG_BASE_SPC_GAINS_L) != 0x40:
            return
        for base, gains in ((_REG_BASE_SPC_GAINS_L, _PDAF_GAINS[0]),
                            (_REG_BASE_SPC_GAINS_R, _PDAF_GAINS[1])):
            for i in range(54):
                self.write_reg(base + i, gains[i % 9])

    def set_exposure(self, lines):
        """Set the exposure time in lines.

        Parameters
        ----------
        lines : int
            Integration time. Clamped to the frame length less the
            blanking the sensor needs, and rounded down to the sensor's
            2-line granularity.
        """
        if self._mode is None:
            raise RuntimeError("configure() the sensor first")
        limit = self._mode.frame_length - _EXPOSURE_OFFSET
        lines = max(_EXPOSURE_MIN, min(lines, limit))
        self.write_reg16(_REG_EXPOSURE, lines - lines % _EXPOSURE_STEP)

    def set_gain(self, analog, digital=_DGTL_GAIN_MIN):
        """Set the analogue and digital gain.

        Parameters
        ----------
        analog : int
            Analogue gain code, 112-960. The gain is 1024 / (1024 - code),
            so 112 is about 1.12x and 960 is 16x.
        digital : int
            Digital gain in 1/256ths, 0x0100 (1x) to 0xFFFF.
        """
        self.write_reg16(_REG_ANALOG_GAIN,
                         max(_ANA_GAIN_MIN, min(analog, _ANA_GAIN_MAX)))
        self.write_reg16(_REG_DIGITAL_GAIN,
                         max(_DGTL_GAIN_MIN, min(digital, _DGTL_GAIN_MAX)))

