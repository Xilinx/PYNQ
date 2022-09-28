#   Copyright (c) 2021, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pynq.ps

from . import clocks, dma
from .common import *

if pynq.ps.CPU_ARCH == pynq.ps.ZYNQ_ARCH:
    from . import dvi
elif pynq.ps.CPU_ARCH == pynq.ps.ZU_ARCH:
    from . import xilinx_hdmi
    from . import pcam5c
    from . import mipi_rx

from . import frontend, hierarchies
from .drm import *


