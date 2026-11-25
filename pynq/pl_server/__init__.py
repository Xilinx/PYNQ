#   Copyright (c) 2016-2022, Xilinx, Inc.
#   Copyright (C) 2022-2026 Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause



import os

from .arch import VersalArch, ZynqArch, ZynqUltrascaleArch
from .device import Device
from .global_state import (
    GlobalState,
    global_state_file_exists,
    load_global_state,
    save_global_state,
)
from .hwh_parser import HWH, get_hwh_name

if os.environ.get("XILINX_XRT", False):
    from .embedded_device import EmbeddedDevice, ZynqDevice, ZynqUltrascaleDevice
    from .versal_device import VersalDevice
    from .xclbin_parser import XclBin
    from .xrt_device import XrtDevice

if os.environ.get("PYNQ_REMOTE_DEVICES", False):
    from .remote_device import (
        RemoteDevice,
        RemoteVersalDevice,
        RemoteZynqDevice,
        RemoteZynqUltrascaleDevice,
    )


