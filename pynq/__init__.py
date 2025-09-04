# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import os
from . import pl_server
from .bitstream import Bitstream
from .buffer import allocate
from .devicetree import DeviceTreeSegment
from .mmio import MMIO
from .overlay import DefaultHierarchy, DefaultIP, Overlay, UnsupportedConfiguration
from .pl import PL
from .pl_server import Device
from .ps import Clocks
from .registers import Register

if os.environ.get("PYNQ_REMOTE_DEVICES", False):
    from .pl_server.remote_device import RemoteGPIO as GPIO
    from .pl_server.remote_device import RemoteInterrupt as Interrupt
    from .pl_server.remote_device import RemoteUioController as UioController   
else:
    from .gpio import GPIO
    from .interrupt import Interrupt
    from .uio import UioController
    from .pmbus import DataRecorder, get_rails

__all__ = ["lib", "tests"]
__version__ = "3.1.1"
# This ID will always be tied to a specific release tag
# since the file will be modified to edit the version
__git_id__ = "$Id$"
