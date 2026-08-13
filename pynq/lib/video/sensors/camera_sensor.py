#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import abc
import glob
import os
import time
import fcntl

_I2C_SLAVE = 0x0703

__all__ = ["CameraSensor"]


class CameraSensor(metaclass=abc.ABCMeta):
    """Base class for MIPI CSI-2 camera sensors driven over raw Linux I2C.

    Every sensor supported by the base overlay uses 16-bit register
    addresses, which standard SMBus cannot express, so all of them talk to
    ``/dev/i2c-N`` directly using file I/O plus an ioctl to select the slave
    address. That plumbing, the bus discovery and the power-up sequencing are
    identical across sensors and live here; subclasses supply the register
    tables and the class metadata below.

    Subclasses must define
    ----------------------
    NAME : str
        Human readable sensor name, used in error messages.
    I2C_ADDR : int
        7-bit I2C slave address.
    ID_REG : int
        Address of the first byte of the chip ID.
    ID_VALUE : int
        Expected chip ID, big-endian across ``ID_NBYTES`` registers.
    HS_SETTLE_NS : int
        D-PHY HS_SETTLE time for this sensor's line rate. Recorded for
        reference only -- it is **not** written at runtime. The
        build-time ``C_HS_SETTLE_NS`` already falls inside the spec
        window for every supported sensor, and overriding it stalled the
        link (see the warning on ``MipiCsi2RxSubsystem.configure``).
    BAYER_PHASE : int
        Default demosaic Bayer phase (0=RGGB, 1=GRBG, 2=GBRG, 3=BGGR).
    WB_GAINS : tuple of float
        Default (red, green, blue) white balance gains applied by the
        colour space converter. Sensors with their own on-chip auto
        white balance leave this at unity; raw sensors need it, because
        silicon is roughly twice as sensitive to green as to red or blue
        and an uncorrected frame comes out visibly green.
    MODES : dict
        Maps ``(width, height, fps)`` to a sensor mode id. Each sensor is
        the source of truth for the modes it supports.

    Parameters
    ----------
    i2c_bus : int
        Linux I2C bus number (e.g. 6 for /dev/i2c-6)
    slave_addr : int or None
        I2C slave address of the sensor. Defaults to ``I2C_ADDR``.
    """

    NAME = None
    I2C_ADDR = None
    ID_REG = None
    ID_VALUE = None
    ID_NBYTES = 2
    #: Lane count the sensor is configured for. Informational only: the
    #: CSI-2 RX subsystem is built with ``C_CSI_EN_ACTIVELANES = false``,
    #: so the lane count is fixed in hardware and cannot be changed here.
    LANE_COUNT = 2
    HS_SETTLE_NS = None
    BAYER_PHASE = 0x0
    #: Unity by default: only raw sensors without on-chip AWB need this.
    WB_GAINS = (1.0, 1.0, 1.0)
    MODES = {}
    #: Delay in seconds after each register write in a configuration table.
    REG_DELAY = 0.01

    def __init__(self, i2c_bus, slave_addr=None):
        self._fd = None
        if slave_addr is None:
            slave_addr = self.I2C_ADDR
        self._fd = os.open(f'/dev/i2c-{i2c_bus}', os.O_RDWR)
        fcntl.ioctl(self._fd, _I2C_SLAVE, slave_addr)

    def close(self):
        # getattr: tolerate a partially constructed object, so a failure in
        # __init__ does not turn into a second error from __del__.
        if getattr(self, '_fd', None) is not None:
            os.close(self._fd)
            self._fd = None

    def __del__(self):
        self.close()

    def write_reg(self, addr, data):
        """Write a single byte to a 16-bit register address."""
        buf = bytes([addr >> 8, addr & 0xFF, data])
        os.write(self._fd, buf)

    def read_reg(self, addr):
        """Read a single byte from a 16-bit register address."""
        buf = bytes([addr >> 8, addr & 0xFF])
        os.write(self._fd, buf)
        return os.read(self._fd, 1)[0]

    def write_reg16(self, addr, data):
        """Write a big-endian 16-bit value to ``addr`` and ``addr + 1``.

        The Sony sensors group most controls (exposure, gain, frame
        length) into register pairs written most-significant byte first.
        """
        self.write_reg(addr, (data >> 8) & 0xFF)
        self.write_reg(addr + 1, data & 0xFF)

    def _write_config(self, table):
        """Write a register configuration table with delays."""
        for addr, data in table:
            self.write_reg(addr, data)
            if self.REG_DELAY:
                time.sleep(self.REG_DELAY)

    def read_id(self):
        """Read the chip ID from ``ID_NBYTES`` registers starting at ID_REG.

        Returns
        -------
        int
            The chip ID, big-endian across consecutive registers.
        """
        value = 0
        for offset in range(self.ID_NBYTES):
            value = (value << 8) | self.read_reg(self.ID_REG + offset)
        return value

    def verify_sensor_id(self):
        """Read the chip ID and check it against ``ID_VALUE``.

        Returns True if the ID matches.

        Raises
        ------
        RuntimeError
            If the chip ID does not match.
        """
        value = self.read_id()
        if value != self.ID_VALUE:
            raise RuntimeError(
                f"{self.NAME} not detected: expected ID "
                f"0x{self.ID_VALUE:04X}, got 0x{value:04X}")
        return True

    @classmethod
    def probe(cls, i2c_bus):
        """Non-destructively test whether this sensor is on ``i2c_bus``.

        Reads the chip ID and compares it against ``ID_VALUE``. Any I/O
        error is treated as "not present": probing an address with nothing
        behind it NAKs, and that must not propagate to the caller, which is
        walking a list of candidate sensors.

        Parameters
        ----------
        i2c_bus : int
            Linux I2C bus number

        Returns
        -------
        bool
            True if this sensor answered with the expected chip ID.
        """
        sensor = None
        try:
            sensor = cls(i2c_bus)
            return sensor.read_id() == cls.ID_VALUE
        except OSError:
            return False
        finally:
            if sensor is not None:
                sensor.close()

    @staticmethod
    def power_cycle(gpio_ip, settle=1.0):
        """Power-cycle the camera sensor via GPIO.

        Pulses CAM_PWUP low then drives high, waiting ``settle`` seconds
        after each edge. The default matches Digilent's reference driver;
        a slow-starting oscillator on the camera needs this long to bring
        the input clock up before the sensor is accessed. The PWUP line is
        the same connector pin for every supported module.

        .. warning::

            This gates sensor power only -- it does **not** isolate the
            MIPI data lines, so it is not a substitute for powering the
            board down before swapping cameras. The CSI connector has no
            hot-plug protection: the flex contacts mate in an arbitrary
            order, so a data lane can connect before ground. Swapping a
            camera on a live board has destroyed modules on this setup,
            the signature being one data lane permanently dead while the
            others still count packets (see ``MipiCamera.diagnostics``).

        Parameters
        ----------
        gpio_ip : DefaultIP
            GPIO IP used for camera power control (channel 2 at offset 0x08)
        settle : float
            Seconds to wait after each power edge.
        """
        gpio_ip.write(0x08, 0)
        time.sleep(settle)
        gpio_ip.write(0x08, 1)
        time.sleep(settle)

    @staticmethod
    def find_i2c_bus():
        """Scan for the camera I2C bus by looking for the 'RPICAM' label.

        Falls back to bus 6 if not found (legacy behavior).

        Returns
        -------
        int
            I2C bus number
        """
        for dev_path in glob.glob('/dev/i2c-*'):
            adapter_number = os.path.basename(dev_path).split('-')[-1]
            name_path = (f'/sys/bus/i2c/devices/i2c-{adapter_number}'
                         f'/of_node/label')
            try:
                with open(name_path, 'r', encoding='utf-8') as f:
                    if 'RPICAM' in f.read().strip():
                        return int(adapter_number)
            except FileNotFoundError:
                continue
        return 6

    @abc.abstractmethod
    def configure(self, mode, gpio_ip, power_cycle=True):
        """Full sensor initialization sequence for the given mode.

        Parameters
        ----------
        mode : int
            Sensor mode id, as found in the values of ``MODES``
        gpio_ip : DefaultIP
            GPIO IP for camera power control
        power_cycle : bool
            Whether to power-cycle the sensor first. Skipped when the
            caller has already powered the camera up, as the hierarchy
            driver does before identifying it over I2C.
        """

    @abc.abstractmethod
    def start(self):
        """Start streaming."""

    @abc.abstractmethod
    def stop(self):
        """Stop streaming."""

    @abc.abstractmethod
    def test_pattern(self, enable=True):
        """Toggle the sensor's built-in test pattern.

        The pattern is generated inside the sensor and streamed over MIPI
        independently of the imaging pipeline, so it isolates the
        MIPI/D-PHY/VDMA transport from sensor imaging configuration.
        """

    @abc.abstractmethod
    def mirror(self):
        """Toggle horizontal mirror on the sensor."""

    @abc.abstractmethod
    def flip(self):
        """Toggle vertical flip on the sensor."""

    def reconfigure(self, mode, gpio_ip):
        """Re-initialize the sensor with a new mode.

        Parameters
        ----------
        mode : int
            Sensor mode id, as found in the values of ``MODES``
        gpio_ip : DefaultIP
            GPIO IP for camera power control
        """
        self.stop()
        self.configure(mode, gpio_ip)
        self.start()
