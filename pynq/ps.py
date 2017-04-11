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

import numpy as np
from .mmio import MMIO


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"

# Clock constants
SRC_CLK_MHZ = 50.0
DEFAULT_CLK_MHZ = 100.0

SCLR_BASE_ADDRESS = 0xf8000000
ARM_PLL_DIV_OFFSET = 0x100
DDR_PLL_DIV_OFFSET = 0x104
IO_PLL_DIV_OFFSET = 0x108
ARM_CLK_REG_OFFSET = 0x120
CLK_CTRL_REG_OFFSET = [0x170, 0x180, 0x190, 0x1A0]
PLL_DIV_LSB = 12
PLL_DIV_MSB = 18
ARM_CLK_SEL_LSB = 4
ARM_CLK_SEL_MSB = 5
ARM_CLK_DIV_LSB = 8
ARM_CLK_DIV_MSB = 13
CLK_SRC_LSB = 4
CLK_SRC_MSB = 5
CLK_DIV0_LSB = 8
CLK_DIV0_MSB = 13
CLK_DIV1_LSB = 20
CLK_DIV1_MSB = 25


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
    max_val0 = 1 << reg0_width
    max_val1 = 1 << reg1_width
    q0 = round(freq_high/freq_desired)
    bound = min(int(q0 / 2), max_val0)
    for i in range(1, bound):
        q1, r1 = divmod(q0, i)
        if i < max_val0-1 and q1 > max_val1-1:
            continue
        if r1 == 0:
            return i, q1
        if i == bound - 1:
            raise ValueError("Not possible to get the desired frequency.")


class Register:
    """Register class that allows users to access registers easily.

    This class supports register slicing, which makes the access to register
    values much more easily. Users can either use +1 or -1 as the step when
    slicing the register. By default, the slice starts from MSB to LSB, which
    is consistent with the common hardware design practice.

    For example, the following slices are acceptable:
    reg[31:13] (commonly used), reg[:], reg[3::], reg[:20:], reg[1:3], etc.

    Note
    ----
    The slicing endpoints are closed, meaning both of the 2 endpoints will
    be included in the final returned value. For example, reg[31:0] will 
    return a 32-bit value; this is consistent with most of the hardware 
    definitions.

    Attributes
    ----------
    address : int
        The address of the register.
    width : int
        The width of the register, e.g., 32 (default) or 64.

    """

    def __init__(self, address, width=32):
        """Instantiate a register object.

        Parameters
        ----------
        address : int
            The address of the register.
        width : int
            The width of the register, e.g., 32 (default) or 64.

        """
        self.address = address
        self.width = width

        if width == 32:
            self._buffer = MMIO(address).array.astype(np.uint32, copy=False)
        elif width == 64:
            self._buffer = MMIO(address).array.astype(np.uint64, copy=False)
        else:
            raise ValueError("Supported register width is 32 or 64.")

    def __getitem__(self, index):
        """Get the register value.

        This method accepts both integer index, or slice as input parameters.

        Parameters
        ----------
        index : int | slice
            The integer index, or slice to access the register value.

        """
        curr_val = int.from_bytes(self._buffer, byteorder='little')
        if isinstance(index, int):
            mask = 1 << index
            return (curr_val & mask) >> index
        elif isinstance(index, slice):
            start, stop, step = index.start, index.stop, index.step
            if step is None or step == -1:
                if start is None:
                    start = self.width - 1
                if stop is None:
                    stop = 0
            elif step == 1:
                if start is None:
                    start = 0
                if stop is None:
                    stop = self.width - 1
            else:
                raise ValueError("Slicing step is not valid.")
            if start not in range(self.width):
                raise ValueError(f"Slicing endpoint {start} is not in range 0"
                                 f" - {self.width}.")
            if stop not in range(self.width):
                raise ValueError(f"Slicing endpoint {stop} is not in range 0"
                                 f" - {self.width}.")

            if start >= stop:
                mask = ((1 << (start - stop + 1)) - 1) << stop
                return (curr_val & mask) >> stop
            else:
                width = stop - start + 1
                mask = ((1 << width) - 1) << start
                reg_val = (curr_val & mask) >> start
                return int('{:0{width}b}'.format(reg_val,
                                                 width=width)[::-1], 2)
        else:
            raise ValueError("Index must be int or slice.")

    def __setitem__(self, index, value):
        """Set the register value.

        This method accepts both integer index, or slice as input parameters.

        Parameters
        ----------
        index : int | slice
            The integer index, or slice to access the register value.

        """
        curr_val = int.from_bytes(self._buffer, byteorder='little')
        if isinstance(index, int):
            if value != 0 and value != 1:
                raise ValueError("Value to be set should be either 0 or 1.")
            mask = 1 << index
            self._buffer[0] = (curr_val & ~mask) | (value << index)
        elif isinstance(index, slice):
            start, stop, step = index.start, index.stop, index.step
            if step is None or step == -1:
                if start is None:
                    start = self.width - 1
                if stop is None:
                    stop = 0
            elif step == 1:
                if start is None:
                    start = 0
                if stop is None:
                    stop = self.width - 1
            else:
                raise ValueError("Slicing step is not valid.")
            if start not in range(self.width):
                raise ValueError(f"Slicing endpoint {start} is not in range 0"
                                 f" - {self.width}.")
            if stop not in range(self.width):
                raise ValueError(f"Slicing endpoint {stop} is not in range 0"
                                 f" - {self.width}.")

            if start >= stop:
                mask = ((1 << (start - stop + 1)) - 1) << stop
                self._buffer[0] = (curr_val & ~mask) | (value << stop)
            else:
                width = stop - start + 1
                mask = ((1 << width) - 1) << start
                reg_val = int('{:0{width}b}'.format(value,
                                                    width=width)[::-1], 2)
                self._buffer[0] = (curr_val & ~mask) | (reg_val << start)
        else:
            raise ValueError("Index must be int or slice.")

    def __str__(self):
        """Print the register value.

        This method is overloaded to print the register value. The output 
        is a string in hex format.

        """
        curr_val = int.from_bytes(self._buffer, byteorder='little')
        return hex(curr_val)


class ClocksMeta(type):
    """Meta class for all the PS and PL clocks not exposed to users.

    Since this is the meta class for all the clocks, no attributes or methods
    are exposed to users. Users should use the class `Clocks` instead.

    """
    arm_pll_reg = Register(SCLR_BASE_ADDRESS + ARM_PLL_DIV_OFFSET)
    ddr_pll_reg = Register(SCLR_BASE_ADDRESS + DDR_PLL_DIV_OFFSET)
    io_pll_reg = Register(SCLR_BASE_ADDRESS + IO_PLL_DIV_OFFSET)
    arm_clk_reg = Register(SCLR_BASE_ADDRESS + ARM_CLK_REG_OFFSET)
    fclk0_reg = Register(SCLR_BASE_ADDRESS + CLK_CTRL_REG_OFFSET[0])
    fclk1_reg = Register(SCLR_BASE_ADDRESS + CLK_CTRL_REG_OFFSET[1])
    fclk2_reg = Register(SCLR_BASE_ADDRESS + CLK_CTRL_REG_OFFSET[2])
    fclk3_reg = Register(SCLR_BASE_ADDRESS + CLK_CTRL_REG_OFFSET[3])

    arm_pll_fdiv = arm_pll_reg[PLL_DIV_MSB:PLL_DIV_LSB]
    ddr_pll_fdiv = ddr_pll_reg[PLL_DIV_MSB:PLL_DIV_LSB]
    io_pll_fdiv = io_pll_reg[PLL_DIV_MSB:PLL_DIV_LSB]
    arm_clk_sel = arm_clk_reg[ARM_CLK_SEL_MSB:ARM_CLK_SEL_LSB]
    arm_clk_div = arm_clk_reg[ARM_CLK_DIV_MSB:ARM_CLK_DIV_LSB]

    @property
    def cpu_mhz(cls):
        """The getter method for CPU clock.

        The returned clock rate is measured in MHz.

        """
        if cls.arm_clk_sel in [0, 1]:
            arm_clk_mult = cls.arm_pll_fdiv
        elif cls.arm_clk_sel == 2:
            arm_clk_mult = cls.ddr_pll_fdiv
        else:
            arm_clk_mult = cls.io_pll_fdiv
        return round(SRC_CLK_MHZ *
                     arm_clk_mult / cls.arm_clk_div, 6)

    @cpu_mhz.setter
    def cpu_mhz(cls, clk_mhz):
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
        return cls._get_fclk(0)

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
        return cls._get_fclk(1)

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
        return cls._get_fclk(2)

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
        return cls._get_fclk(3)

    @fclk3_mhz.setter
    def fclk3_mhz(cls, clk_mhz):
        """The setter method for PL clock 3.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_fclk(3, clk_mhz=clk_mhz)

    def _get_fclk(cls, clk_idx):
        """This method will return the clock frequency.
        
        This method is not exposed to users.

        Parameters
        ----------
        clk_idx : int
            The index of the PL clock to be changed, from 0 to 3.

        """
        if clk_idx == 0:
            clk_reg = cls.fclk0_reg
        elif clk_idx == 1:
            clk_reg = cls.fclk1_reg
        elif clk_idx == 2:
            clk_reg = cls.fclk2_reg
        elif clk_idx == 3:
            clk_reg = cls.fclk3_reg
        else:
            raise ValueError("Valid PL clock index is 0 - 3.")

        fclk_src = clk_reg[CLK_SRC_MSB:CLK_SRC_LSB]
        fclk_div0 = clk_reg[CLK_DIV0_MSB:CLK_DIV0_LSB]
        fclk_div1 = clk_reg[CLK_DIV1_MSB:CLK_DIV1_LSB]
        if fclk_src in [0, 1]:
            fclk_mult = cls.io_pll_fdiv
        elif src == 2:
            fclk_mult = cls.arm_pll_fdiv
        else:
            fclk_mult = cls.ddr_pll_fdiv

        return round(SRC_CLK_MHZ *
                     fclk_mult / (fclk_div0 * fclk_div1), 6)

    def set_fclk(cls, clk_idx, div0=None, div1=None, clk_mhz=DEFAULT_CLK_MHZ):
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
        if clk_idx == 0:
            clk_reg = cls.fclk0_reg
        elif clk_idx == 1:
            clk_reg = cls.fclk1_reg
        elif clk_idx == 2:
            clk_reg = cls.fclk2_reg
        elif clk_idx == 3:
            clk_reg = cls.fclk3_reg
        else:
            raise ValueError("Valid PL clock index is 0 - 3.")

        fclk_src = clk_reg[CLK_SRC_MSB:CLK_SRC_LSB]
        if fclk_src in [0, 1]:
            fclk_mult = cls.io_pll_fdiv
        elif fclk_src == 2:
            fclk_mult = cls.arm_pll_fdiv
        else:
            fclk_mult = cls.ddr_pll_fdiv

        max_clk_mhz = SRC_CLK_MHZ * fclk_mult
        div0_width = CLK_DIV0_MSB - CLK_DIV0_LSB + 1
        div1_width = CLK_DIV1_MSB - CLK_DIV1_LSB + 1
        max_div0 = 1 << div0_width
        max_div1 = 1 << div1_width

        if div0 is None and div1 is None:
            div0, div1 = _get_2_divisors(max_clk_mhz, clk_mhz,
                                         div0_width, div1_width)
        elif div0 is not None and div1 is None:
            div1 = round(max_clk_mhz / clk_mhz / div0)
        elif div1 is not None and div0 is None:
            div0 = round(max_clk_mhz / clk_mhz / div1)

        if not 0 < div0 <= max_div0:
            raise ValueError("Frequency divider 0 value out of range.")
        if not 0 < div1 <= max_div1:
            raise ValueError("Frequency divider 1 value out of range.")

        clk_reg[CLK_DIV0_MSB:CLK_DIV0_LSB] = div0
        clk_reg[CLK_DIV1_MSB:CLK_DIV1_LSB] = div1


class Clocks(metaclass=ClocksMeta):
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
