#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""MIPI CSI-2 camera sensor drivers for the base overlay.

Each sensor is a :class:`CameraSensor` subclass carrying its own register
tables plus the metadata the hierarchy driver needs to program the rest of
the pipeline (D-PHY HS_SETTLE, Bayer phase, supported modes).
"""

from .camera_sensor import CameraSensor
from .ov5640 import OV5640

SENSORS = (OV5640,)

__all__ = ["CameraSensor", "OV5640", "SENSORS", "detect_sensor"]


def detect_sensor(i2c_bus=None):
    """Identify the camera attached to the MIPI connector.

    Probes each sensor in :data:`SENSORS` in turn by reading its chip ID
    register. Probing is read-only and tolerates a NAK, so an absent
    sensor simply does not match.

    Parameters
    ----------
    i2c_bus : int or None
        Linux I2C bus number. Discovered via
        :meth:`CameraSensor.find_i2c_bus` when None.

    Returns
    -------
    type or None
        The matching :class:`CameraSensor` subclass, or None if no
        supported camera answered.
    """
    if i2c_bus is None:
        i2c_bus = CameraSensor.find_i2c_bus()
    for sensor_cls in SENSORS:
        if sensor_cls.probe(i2c_bus):
            return sensor_cls
    return None
