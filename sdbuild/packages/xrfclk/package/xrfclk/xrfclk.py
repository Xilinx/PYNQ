#   Copyright (c) 2021, Xilinx, Inc.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import os
import glob
import re
import cffi
from collections import defaultdict


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


board = os.environ['BOARD']
if board == "ZCU111":
    _iic_channel = 12
elif board == "RFSoC2x2":
    _iic_channel = 7
else:
    raise ValueError("Board {} is not supported.".format(board))


_ffi = cffi.FFI()
_ffi.cdef("int clearInt(int IicNum);"
          "int writeLmkRegs(int IicNum, unsigned int *RegVals);"
          "int writeLmx2594Regs(int IicNum, unsigned int *RegVals);")
_lib = _ffi.dlopen(os.path.join(os.path.dirname(__file__), 'libxrfclk.so'))


_lmx2594Config = defaultdict(list)
_lmk04208Config= defaultdict(list)
_lmk04832Config = defaultdict(list)


def _safe_wrapper(name, *args, **kwargs):
    """Wrapper function for FFI function calls.

    """
    if not hasattr(_lib, name):
        raise RuntimeError("Function {} not in library.".format(name))
    if getattr(_lib, name)(*args, **kwargs):
        raise RuntimeError("Function {} call failed.".format(name))


def clear_int():
    """Clear the interrupts.

    """
    _safe_wrapper("clearInt", _iic_channel)


def write_LMK_regs(reg_vals):
    """Write values to the LMK registers.

    This is an internal function.

    Parameters
    ----------
    reg_vals: list
        A list of 32-bit register values (LMK clock dependant number of values).
        LMK04208 = 32 registers
        LMK04832 = 125 registers

    """
    _safe_wrapper("writeLmkRegs", _iic_channel, reg_vals)
    
def write_LMX_regs(reg_vals):
    """Write values to the LMX registers.

    This is an internal function.

    Parameters
    ----------
    reg_vals: list
        A list of 113 32-bit register values.

    """
    _safe_wrapper("writeLmx2594Regs", _iic_channel, reg_vals)
    
def set_LMX_clks(LMX_freq):
    """Set LMX chip frequency.

    Parameters
    ----------
    lmx_freq: float
        The frequency for the LMX PLL chip.

    """
    if LMX_freq not in _lmx2594Config:
        raise RuntimeError("Frequency {} MHz is not valid.".format(LMX_freq))
    else:
        write_LMX_regs(_lmx2594Config[LMX_freq])
        
def set_LMK_clks(LMK_freq):
    """Set LMK chip frequency.

    Parameters
    ----------
    lmx_freq: float
        The frequency for the LMX PLL chip.

    """
    if board == "ZCU111":
        if LMK_freq not in _lmk04208Config:
            raise RuntimeError("Frequency {} MHz is not valid.".format(LMK_freq))
        else:
            write_LMK_regs(_lmk04208Config[LMK_freq])
    elif board == "RFSoC2x2":
        if LMK_freq not in _lmk04832Config:
            raise RuntimeError("Frequency {} MHz is not valid.".format(LMK_freq))
        else:
            write_LMK_regs(_lmk04832Config[LMK_freq])
        else:
            write_LMK_regs(_lmk04828bConfig[LMK_freq])
    else:
        raise ValueError("Board {} is not supported.".format(board))


def set_ref_clks(lmk_freq=122.88, lmx_freq=409.6):
    """Set all RF data converter tile reference clocks to a given frequency.

    LMX chips are downstream so make sure LMK chips are enabled first.

    Parameters
    ----------
    lmk_freq: float
        The frequency for the LMK clock generation chip.
    lmx_freq: float
        The frequency for the LMX PLL chip.

    """
    read_tics_output()
    set_LMK_clks(lmk_freq)
    set_LMX_clks(lmx_freq)


def read_tics_output():
    """Read all the TICS register values from all the txt files.

    Reading all the configurations from the current directory. We assume the
    file has a format `CHIPNAME_frequency.txt`.

    """
    dir_path = os.path.dirname(os.path.realpath(__file__))
    all_txt = glob.glob(os.path.join(dir_path, '*.txt'))
    for s in all_txt:
        chip, freq = s.lower().split('/')[-1].strip('.txt').split('_')
        config = eval('_{}Config'.format(chip))
        with open(s, 'r') as f:
            lines = [l.rstrip("\n") for l in f]
            for i in lines:
                m = re.search('[\t]*(0x[0-9A-F]*)', i)
                config[float(freq)] += int(m.group(1), 16),

