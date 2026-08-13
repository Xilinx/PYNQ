#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""MIPI CSI-2 camera sensor drivers for the base overlay.

Each sensor is a :class:`CameraSensor` subclass carrying its own register
tables plus the metadata the hierarchy driver needs to program the rest of
the pipeline (D-PHY HS_SETTLE, Bayer phase, supported modes).
"""

from .camera_sensor import CameraSensor
from .sony_sensor import SonySensor
from .imx219 import IMX219
from .imx708 import IMX708
from .ov5640 import OV5640

#: Sensors probed by :func:`detect_sensor`. All sit at distinct I2C
#: addresses, so the order only fixes the failure message.
SENSORS = (OV5640, IMX219, IMX708)

__all__ = ["CameraSensor", "SonySensor", "OV5640", "IMX219", "IMX708",
           "SENSORS", "detect_sensor"]


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
