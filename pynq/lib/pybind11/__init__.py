#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from .compile import Pybind11Compile
from .proc import Pybind11Processor
try:
    __IPYTHON__
    from .magic import Pybind11Magics
except NameError:
    pass




