#   Copyright (c) 2016, Xilinx, Inc.
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

from .mmio import MMIO
from . import general_const

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _get_reg_value(addr,bit_offset,bit_width):
    """Return register value at the given address.

    Parameters
    ----------
    addr : int
        The address of the register.
    bit_offset : int
        The offset of bits to get the binary digits.
    bit_width : int
        The width of the bits for returned binary digits.

    Returns
    -------
    int
        The register value at the given address and bit offset.

    """
    if bit_offset not in range(32):
        raise ValueError("Bit starting offset should be 0 - 31.")
    if bit_width not in range(32):
        raise ValueError("Bit width should be 0 - 31.")
    if (bit_offset + bit_width) not in range(32):
        raise ValueError("Bit ending offset should be 0 - 31.")

    mask = int('1' * bit_width, 2) << bit_offset
    cur_val = MMIO(addr).read()
    return (cur_val & mask) >> bit_offset


def _set_reg_value(addr, bit_offset, bit_width, value):
    """Set register value at the given address.

    This method does read-modify-write to set the register value.

    Parameters
    ----------
    addr : int
        The address of the register.
    bit_offset : int
        The offset of bits to set the binary digits.
    bit_width : int
        The width of the bits to set binary digits.
    value : int
        The integer value to write into the register.

    """
    if bit_offset not in range(32):
        raise ValueError("Bit starting offset should be 0 - 31.")
    if bit_width not in range(32):
        raise ValueError("Bit width should be 0 - 31.")
    if (bit_offset + bit_width) not in range(32):
        raise ValueError("Bit ending offset should be 0 - 31.")

    mask1 = int('1' * bit_width, 2)
    mask0 = ~(mask1 << bit_offset)
    bit_val = (value & mask1) << bit_offset
    register = MMIO(addr, 4)
    rst_val = register.read() & mask0
    register.write(0, rst_val | bit_val)

def _get_2_divisors(freq_high, freq_desired, reg0_width, reg1_width):
    """Return 2 divisors of the specified width for frequency divider.

    Exception will be raised if no such pair of divisors can be found.

    Parameters
    ----------
    freq_high : float
        High frequency to be divided.
    freq_desired : float
        Desired frequency to be get.
    reg0_width: int
        The register width of the first divisor.
    reg1_width : int
        The register width of the second divisor.

    Returns
    -------
    tuple
        A pair of 2 divisors, each of 6 bits at most.

    """
    max_val0 = 1<<reg0_width
    max_val1 = 1<<reg1_width
    q0 = round(freq_high/freq_desired)
    bound = min(int(q0 / 2), max_val0)
    for i in range(1,bound):
        q1,r1 = divmod(q0,i)
        if i<max_val0-1 and q1>max_val1-1:
            continue
        if r1 == 0:
            return i,q1
        if i == bound - 1:
            raise ValueError("Not possible to get the desired frequency.")

arm_pll_fdiv = _get_reg_value(general_const.SCLR_BASE_ADDRESS +
                              general_const.ARM_PLL_DIV_OFFSET,
                              general_const.PLL_DIV_BIT_OFFSET,
                              general_const.PLL_DIV_BIT_WIDTH)
ddr_pll_fdiv = _get_reg_value(general_const.SCLR_BASE_ADDRESS +
                              general_const.DDR_PLL_DIV_OFFSET,
                              general_const.PLL_DIV_BIT_OFFSET,
                              general_const.PLL_DIV_BIT_WIDTH)
io_pll_fdiv = _get_reg_value(general_const.SCLR_BASE_ADDRESS +
                             general_const.IO_PLL_DIV_OFFSET,
                             general_const.PLL_DIV_BIT_OFFSET,
                             general_const.PLL_DIV_BIT_WIDTH)
arm_clk_sel = _get_reg_value(general_const.SCLR_BASE_ADDRESS +
                             general_const.ARM_CLK_REG_OFFSET,
                             general_const.ARM_CLK_SEL_BIT_OFFSET,
                             general_const.ARM_CLK_SEL_BIT_WIDTH)
arm_clk_div = _get_reg_value(general_const.SCLR_BASE_ADDRESS +
                             general_const.ARM_CLK_REG_OFFSET,
                             general_const.ARM_CLK_DIV_BIT_OFFSET,
                             general_const.ARM_CLK_DIV_BIT_WIDTH)

class Clocks_Meta(type):
    """Meta class for all the PS and PL clocks not exposed to users.

    Since this is the meta class for all the clocks, no attributes or methods
    are exposed to users. Users should use the class `Clocks` instead.

    """
    @property
    def cpu_mhz(cls):
        """The getter method for CPU clock.

        The returned clock rate is measured in MHz.

        """
        if arm_clk_sel in [0,1]:
            arm_clk_mult = arm_pll_fdiv
        elif arm_clk_sel == 2:
            arm_clk_mult = ddr_pll_fdiv
        else:
            arm_clk_mult = io_pll_fdiv
        return round(general_const.SRC_CLK_MHZ *
                             arm_clk_mult / arm_clk_div, 6)

    @cpu_mhz.setter
    def cpu_mhz(cls,clk_mhz):
        """The setter method for CPU clock.

        Since the CPU clock should not be changed, setting it will raise
        an exception.

        """
        raise RuntimeError("Not allowed to change CPU clock.")
    
    @property
    def fclk0_mhz(cls):
        """The getter method for PL clock 0.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        clk_idx = 0
        offset = general_const.CLK_CTRL_REG_OFFSET[clk_idx]
        fclk_src = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                  general_const.CLK_SRC_BIT_OFFSET,
                                  general_const.CLK_SRC_BIT_WIDTH)
        fclk_div0 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV0_BIT_OFFSET,
                                   general_const.CLK_DIV0_BIT_WIDTH)
        fclk_div1 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV1_BIT_OFFSET,
                                   general_const.CLK_DIV1_BIT_WIDTH)
        if fclk_src in [0, 1]:
            fclk_mult = io_pll_fdiv
        elif src == 2:
            fclk_mult = arm_pll_fdiv
        else:
            fclk_mult = ddr_pll_fdiv

        return round(general_const.SRC_CLK_MHZ *
                     fclk_mult / (fclk_div0 * fclk_div1), 6)

    @fclk0_mhz.setter
    def fclk0_mhz(cls, clk_mhz):
        """The setter method for PL clock 0.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_fclk(0, clk_mhz=clk_mhz)

    @property
    def fclk1_mhz(cls):
        """The getter method for PL clock 1.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        clk_idx = 1
        offset = general_const.CLK_CTRL_REG_OFFSET[clk_idx]
        fclk_src = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                  general_const.CLK_SRC_BIT_OFFSET,
                                  general_const.CLK_SRC_BIT_WIDTH)
        fclk_div0 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV0_BIT_OFFSET,
                                   general_const.CLK_DIV0_BIT_WIDTH)
        fclk_div1 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV1_BIT_OFFSET,
                                   general_const.CLK_DIV1_BIT_WIDTH)
        if fclk_src in [0, 1]:
            fclk_mult = io_pll_fdiv
        elif src == 2:
            fclk_mult = arm_pll_fdiv
        else:
            fclk_mult = ddr_pll_fdiv

        return round(general_const.SRC_CLK_MHZ *
                     fclk_mult / (fclk_div0 * fclk_div1), 6)

    @fclk1_mhz.setter
    def fclk1_mhz(cls, clk_mhz):
        """The setter method for PL clock 1.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_fclk(1, clk_mhz=clk_mhz)

    @property
    def fclk2_mhz(cls):
        """The getter method for PL clock 2.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        clk_idx = 2
        offset = general_const.CLK_CTRL_REG_OFFSET[clk_idx]
        fclk_src = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                  general_const.CLK_SRC_BIT_OFFSET,
                                  general_const.CLK_SRC_BIT_WIDTH)
        fclk_div0 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV0_BIT_OFFSET,
                                   general_const.CLK_DIV0_BIT_WIDTH)
        fclk_div1 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV1_BIT_OFFSET,
                                   general_const.CLK_DIV1_BIT_WIDTH)
        if fclk_src in [0, 1]:
            fclk_mult = io_pll_fdiv
        elif src == 2:
            fclk_mult = arm_pll_fdiv
        else:
            fclk_mult = ddr_pll_fdiv

        return round(general_const.SRC_CLK_MHZ *
                     fclk_mult / (fclk_div0 * fclk_div1), 6)

    @fclk2_mhz.setter
    def fclk2_mhz(cls, clk_mhz):
        """The setter method for PL clock 2.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_fclk(2, clk_mhz=clk_mhz)

    @property
    def fclk3_mhz(cls):
        """The getter method for PL clock 3.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        clk_idx = 3
        offset = general_const.CLK_CTRL_REG_OFFSET[clk_idx]
        fclk_src = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                  general_const.CLK_SRC_BIT_OFFSET,
                                  general_const.CLK_SRC_BIT_WIDTH)
        fclk_div0 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV0_BIT_OFFSET,
                                   general_const.CLK_DIV0_BIT_WIDTH)
        fclk_div1 = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                   general_const.CLK_DIV1_BIT_OFFSET,
                                   general_const.CLK_DIV1_BIT_WIDTH)
        if fclk_src in [0, 1]:
            fclk_mult = io_pll_fdiv
        elif src == 2:
            fclk_mult = arm_pll_fdiv
        else:
            fclk_mult = ddr_pll_fdiv

        return round(general_const.SRC_CLK_MHZ *
                     fclk_mult / (fclk_div0 * fclk_div1), 6)

    @fclk3_mhz.setter
    def fclk3_mhz(cls, clk_mhz):
        """The setter method for PL clock 3.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_fclk(3, clk_mhz=clk_mhz)

    @staticmethod
    def set_fclk(clk_idx, div0=None, div1=None, clk_mhz=100.000000):
        """This method can set a PL clock frequency.

        Users have to specify the index of the PL clock to be changed.
        For example, for fclk1, `clk_idx` is 1.

        The CPU clock, by default, should not get changed.

        Users have 2 options:
        1. specify the 2 frequency divider values directly, or
        2. specify the clock rate, in which case the divider values will be
        calculated.

        Note
        ----
        In case `div0` and `div1` are both specified, the parameter `clk_mhz`
        will be ignored.

        Parameters
        ----------
        clk_idx : int
            The index of the PL clock to be changed, from 0 to 3.
        div0 : int
            The first frequency divider value.
        div1 : int
            The second frequency divider value.
        clk_mhz : float
            The clock rate in MHz.

        """
        if clk_idx not in range(4):
            raise ValueError("Valid PL clock index is 0 - 3.")

        offset = general_const.CLK_CTRL_REG_OFFSET[clk_idx]
        fclk_src = _get_reg_value(general_const.SCLR_BASE_ADDRESS + offset,
                                  general_const.CLK_SRC_BIT_OFFSET,
                                  general_const.CLK_SRC_BIT_WIDTH)
        if fclk_src in [0, 1]:
            fclk_mult = io_pll_fdiv
        elif fclk_src == 2:
            fclk_mult = arm_pll_fdiv
        else:
            fclk_mult = ddr_pll_fdiv

        max_clk_mhz = general_const.SRC_CLK_MHZ * fclk_mult
        max_div0 = 1 << general_const.CLK_DIV0_BIT_WIDTH
        max_div1 = 1 << general_const.CLK_DIV1_BIT_WIDTH

        if div0 is None and div1 is None:
            div0, div1 = _get_2_divisors(max_clk_mhz, clk_mhz,
                                         general_const.CLK_DIV0_BIT_WIDTH,
                                         general_const.CLK_DIV1_BIT_WIDTH)
        elif div0 is not None and div1 is None:
            div1 = round(max_clk_mhz/ clk_mhz / div0)
        elif div1 is not None and div0 is None:
            div0 = round(max_clk_mhz / clk_mhz / div1)

        if not 0 < div0 <= max_div0:
            raise ValueError("Frequency divider 0 value out of range.")
        if not 0 < div1 <= max_div1:
            raise ValueError("Frequency divider 1 value out of range.")

        _set_reg_value(general_const.SCLR_BASE_ADDRESS +
                       general_const.CLK_CTRL_REG_OFFSET[clk_idx],
                       general_const.CLK_DIV0_BIT_OFFSET,
                       general_const.CLK_DIV0_BIT_WIDTH, div0)
        _set_reg_value(general_const.SCLR_BASE_ADDRESS +
                       general_const.CLK_CTRL_REG_OFFSET[clk_idx],
                       general_const.CLK_DIV1_BIT_OFFSET,
                       general_const.CLK_DIV1_BIT_WIDTH, div1)

class Clocks(metaclass=Clocks_Meta):
    """Class for all the PS and PL clocks exposed to users.

    With this class, users can get the CPU clock and all the PL clocks. Users
    can also set PL clocks to other values using this class.

    Attributes
    ----------
    cpu_mhz : float
        The clock rate of the CPU, measured in MHz.
    fclk0_mhz : float
        The clock rate of the PL clock 0, measured in MHz.
    fclk1_mhz : float
        The clock rate of the PL clock 1, measured in MHz.
    fclk2_mhz : float
        The clock rate of the PL clock 2, measured in MHz.
    fclk3_mhz : float
        The clock rate of the PL clock 3, measured in MHz.

    """
    def __init__(self):
        """Return a new PL object.

        This class requires a root permission.

        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')