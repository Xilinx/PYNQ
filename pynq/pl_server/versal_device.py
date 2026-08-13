#   Copyright (C) 2026 Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import os

from pynq.ps import _is_versal_host

from .embedded_device import EmbeddedDevice

__all__ = ["VersalDevice"]


class VersalDevice(EmbeddedDevice):
    """Device for the Versal Adaptive SoCs.

    Versal reconfigures the PL through the same Linux FPGA Manager
    interface as Zynq Ultrascale+, so MMIO, XRT memory and the download
    flow are all inherited. The bitstream is a Programmable Device Image
    (.pdi) loaded on top of the boot PDI the PLM programmed at boot.

    """

    # Probed in preference to EmbeddedDevice, which is 50.
    _probe_priority_ = 40

    @classmethod
    def _probe_(cls):
        if _is_versal_host():
            return [VersalDevice()]
        else:
            return []

    def __init__(self, index=0, tag="versal_xrt{}"):
        super().__init__(index, tag)

    def write_fpga_manager(self, attribute, value):
        """Write to an FPGA Manager sysfs attribute using `os.write`.

        Parameters
        ----------
        attribute : str
            The path of the sysfs attribute to write.
        value : str
            The value to write.

        """
        fd = os.open(attribute, os.O_WRONLY)
        try:
            os.write(fd, value.encode())
        finally:
            os.close(fd)
