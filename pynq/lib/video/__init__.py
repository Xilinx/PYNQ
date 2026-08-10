#   Copyright (c) 2021, Xilinx, Inc.
#   Copyright (c) 2026, Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pynq.ps

from . import clocks, dma
from .common import *

if pynq.ps.CPU_ARCH == pynq.ps.ZYNQ_ARCH:
    from . import dvi
elif pynq.ps.CPU_ARCH == pynq.ps.ZU_ARCH:
    from . import xilinx_hdmi
    from . import mipi_rx
    from .mipi_camera import MipiCamera, MIPIMode
    from .sensors import CameraSensor, SENSORS, detect_sensor
    from .sensors import OV5640, IMX219, IMX708
    from .demosaic import Demosaic
    from .gamma_lut import GammaLut
    from .video_proc_ss import VideoProcessingCSC

from . import frontend, hierarchies
from .drm import *
