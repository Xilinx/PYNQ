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
import os
import warnings
from .mmio import MMIO

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"

# Pynq Family Constants
ZYNQ_ARCH = "armv7l"
ZU_ARCH = "aarch64"
CPU_ARCH = os.uname().machine
CPU_ARCH_IS_SUPPORTED = CPU_ARCH in [ZYNQ_ARCH, ZU_ARCH]

DEFAULT_PL_CLK_MHZ = 100.0

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

    def __init__(self, address, width=32, debug = False):
        """Instantiate a register object.

        Parameters
        ----------
        address : int
            The address of the register.
        width : int
            The width of the register, e.g., 32 (default) or 64.
        debug : bool
            Turn on debug mode if True; default is False.

        """
        
        self.address = address
        self.width = width
        self.debug = debug

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
            self._debug("Reading index {} at address {}"
                        .format(index, hex(self.address)))
            mask = 1 << index
            return (curr_val & mask) >> index
        elif isinstance(index, slice):
            start, stop, step = index.start, index.stop, index.step
            self._debug("Reading bits {}:{} at address {}"
                        .format(start, stop, hex(self.address)))
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
                raise ValueError("Slicing endpoint {} is not in range 0".format(start),
                                 " - {}.".format(self.width))
            if stop not in range(self.width):
                raise ValueError("Slicing endpoint {stop} is not in range 0".format(stop),
                                 " - {}.".format(self.width))

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
            self._debug("Setting bit {} at address {} to {}"
                        .format(index, hex(self.address), value))
            mask = 1 << index
            self._buffer[0] = (curr_val & ~mask) | (value << index)
        elif isinstance(index, slice):
            count = self.count(index, width = self.width)
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
                raise ValueError("Slicing endpoint {} is not in range 0 - {}."
                                 .format(start, self.width))
            if stop not in range(self.width):
                raise ValueError("Slicing endpoint {} is not in range 0 - {}."
                                 .format(stop, self.width))
            if value not in range(1 << count):
                raise ValueError("Slicing range cannot represent value {}"
                                 .format(value))

            shift = stop if start >= stop else start
            mask = ((1 << count) - 1) << shift
            self._debug("Setting bits {}:{} at address {} to {}"
                         .format(count + shift, shift, hex(self.address), value))
            self._buffer[0] = (curr_val & ~mask) | (value << shift)
        else:
            raise ValueError("Index must be int or slice.")

    def __str__(self):
        """Print the register value.

        This method is overloaded to print the register value. The output 
        is a string in hex format.

        """

        curr_val = int.from_bytes(self._buffer, byteorder='little')
        return hex(curr_val)

    def _debug(self, s, *args):
        """The method provides debug capabilities for this class.

        Parameters
        ----------
        s : str
            The debug information format string
        *args : any
            The arguments to be formatted
        Returns
        -------
        None

        """
        if self.debug:
            print('Register Debug: {0}'.format(s.format(*args)))

    @classmethod
    def count(cls, index, width=32):
        """Provide the number of bits accessed by an index or slice

        This method accepts both integer index, or slice as input parameters.

        Parameters
        ----------
        index : int | slice
            The integer index, or slice to access the register value.

        """
        
        if isinstance(index, int):
            return 1
        elif isinstance(index, slice):
            start, stop, step = index.start, index.stop, index.step
            if step is None or step == -1:
                if start is None:
                    start = width - 1
                if stop is None:
                    stop = 0
            elif step == 1:
                if start is None:
                    start = 0
                if stop is None:
                    stop = width - 1
            else:
                raise ValueError("Slicing step is not valid.")
            if start not in range(width):
                raise ValueError("Slicing endpoint {} is not in range(0,{})."
                                 .format(start, self.width))
            if stop not in range(width):
                raise ValueError("Slicing endpoint {} is not in range(, {})."
                                 .format(stop, self.width))

            if start >= stop:
                count = start - stop + 1
            else:
                count = stop - start + 1
            return count

class _Clocks(type):
    """Meta class for all the PS and PL clocks not exposed to users.

    Since this is the abstract base class for all the clocks, no 
    attributes or methods are exposed to users. Users should use the class 
    `Clocks` instead.

    Note
    ----
    If this class is parsed on an unsupported architecture it will issue
    a warning and leave class variables undefined

    """

    @property
    def cpu_mhz(cls):
        """The getter method for CPU clock.

        The returned clock rate is measured in MHz.

        """
        return cls._cpu_mhz()

    @cpu_mhz.setter
    def cpu_mhz(cls, clk_mhz):
        """The setter method for CPU clock.

        Since the CPU clock should not be changed, setting it will raise
        an exception.

        """
        raise RuntimeError("Not allowed to change CPU clock.")

    @property
    def pl_clk_0_mhz(cls):
        """The getter method for PL clock 0.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        return cls._get_pl_clk(0)

    @pl_clk_0_mhz.setter
    def pl_clk_0_mhz(cls, clk_mhz):
        """The setter method for PL clock 0.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_pl_clk(0, clk_mhz=clk_mhz)

    @property
    def pl_clk_1_mhz(cls):
        """The getter method for PL clock 1.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        return cls._get_pl_clk(1)

    @pl_clk_1_mhz.setter
    def pl_clk_1_mhz(cls, clk_mhz):
        """The setter method for PL clock 1.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_pl_clk(1, clk_mhz=clk_mhz)

    @property
    def pl_clk_2_mhz(cls):
        """The getter method for PL clock 2.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        return cls._get_pl_clk(2)

    @pl_clk_2_mhz.setter
    def pl_clk_2_mhz(cls, clk_mhz):
        """The setter method for PL clock 2.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_pl_clk(2, clk_mhz=clk_mhz)

    @property
    def pl_clk_3_mhz(cls):
        """The getter method for PL clock 3.

        This method will read the register values, do the calculation,
        and return the current clock rate.

        Returns
        -------
        float
            The returned clock rate measured in MHz.

        """
        return cls._get_pl_clk(3)

    @pl_clk_3_mhz.setter
    def pl_clk_3_mhz(cls, clk_mhz):
        """The setter method for PL clock 3.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls.set_pl_clk(3, clk_mhz=clk_mhz)

    @classmethod
    def _get_pl_clk(cls, clk_idx):
        """This method will return the clock frequency.
        
        This method is not exposed to users.

        Parameters
        ----------
        clk_idx : int
            The index of the PL clock to be changed, from 0 to 3.

        """
        try:
            pl_clk_reg = cls.PL_CLK_CTRLS[clk_idx]
        except:
            raise ValueError("Valid PL clock index is 0 - 3.")

        src_clk_idx = pl_clk_reg[cls.PL_CLK_SRC_FIELD]        
        src_clk_mhz = cls._get_src_clk_mhz(src_clk_idx)
        pl_clk_odiv0 = pl_clk_reg[cls.PL_CLK_ODIV0_FIELD]
        pl_clk_odiv1 = pl_clk_reg[cls.PL_CLK_ODIV1_FIELD]

        return round(src_clk_mhz / (pl_clk_odiv0 * pl_clk_odiv1), 6)

    @classmethod
    def set_pl_clk(cls, clk_idx, div0=None, div1=None, \
                   clk_mhz=DEFAULT_PL_CLK_MHZ):
        """This method sets a PL clock frequency.

        Users have to specify the index of the PL clock to be changed.
        For example, for fclk1 (Zynq) or pl1_clk (ZynqUltrascale), 
        `clk_idx` is 1.

        The CPU, and other source clocks, by default, should not get changed.

        Users have two options:
        1. specify the two frequency divider values directly (div0, div1), or
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
        try:
            pl_clk_reg = cls.PL_CLK_CTRLS[clk_idx]
        except:
            raise ValueError("Valid PL clock index is 0 - 3.")

        div0_width = Register.count(cls.PL_CLK_ODIV0_FIELD)
        div1_width = Register.count(cls.PL_CLK_ODIV1_FIELD)
        src_clk_idx = pl_clk_reg[cls.PL_CLK_SRC_FIELD]
        src_clk_mhz = cls._get_src_clk_mhz(src_clk_idx)

        if div0 is None and div1 is None:
            div0, div1 = cls._get_2_divisors(src_clk_mhz, clk_mhz,
                                             div0_width, div1_width)
        elif div0 is not None and div1 is None:
            div1 = round(src_clk_mhz / clk_mhz / div0)
        elif div1 is not None and div0 is None:
            div0 = round(src_clk_mhz / clk_mhz / div1)

        if div0 <= 0 or div0 > ((1 << div0_width) - 1):
            raise ValueError("Frequency divider 0 value out of range.")
        if div1 <= 0 or div1 > ((1 << div1_width) - 1):
            raise ValueError("Frequency divider 1 value out of range.")
        
        pl_clk_reg[cls.PL_CLK_ODIV0_FIELD] = div0
        pl_clk_reg[cls.PL_CLK_ODIV1_FIELD] = div1

    @classmethod
    def _get_src_clk_mhz(cls, clk_idx):
        """The getter method for PL clock (pl_clk) sources.

        The returned clock rate is measured in MHz.

        """
        
        try:
            src_pll_reg = cls.PL_SRC_PLL_CTRLS[clk_idx]
        except:
            raise ValueError("Valid source clock index is 0 - 3.")
        
        return round(cls._get_pll_mhz(src_pll_reg), 6)

    @classmethod
    def _get_2_divisors(cls, freq_high, freq_desired, reg0_width, reg1_width):
        """Return 2 divisors of the specified width for frequency divider.

        Warning will be raised if the closest clock rate achievable 
        differs more than 1 percent of the desired value.

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
        div_product_desired = round(freq_high / freq_desired, 6)
        _, q0 = min(enumerate(cls.VALID_CLOCK_DIV_PRODUCTS),
                    key=lambda x: abs(x[1] - div_product_desired))
        if abs(freq_desired - freq_high / q0) > 0.01 * freq_desired:
            warnings.warn(
                "Setting frequency to the closet possible value {}MHz.".format(
                    round(freq_high / q0, 5)))

        max_val0 = 1 << reg0_width
        max_val1 = 1 << reg1_width
        for i in range(1, max_val0):
            for j in range(1, max_val1):
                if i * j == q0:
                    return i, j
            
class _ClocksUltrascale(_Clocks):
    """Implementation class for all Zynq Ultrascale PS and PL clocks
    not exposed to users.

    Since this is the abstract base class for all Zynq Ultrascale clocks, no 
    attributes or methods are exposed to users. Users should use the class 
    `Clocks` instead.

    """
    DEFAULT_SRC_CLK_MHZ = 33.333
    
    # Registers in the CRL "Namespace"
    CRL_APB_ADDRESS = 0xFF5E0000
    IOPLL_CTRL_OFFSET = 0x20
    RPLL_CTRL_OFFSET = 0x30

    PL0_CTRL_OFFSET = 0xC0
    PL1_CTRL_OFFSET = 0xC4
    PL2_CTRL_OFFSET = 0xC8
    PL3_CTRL_OFFSET = 0xCC
    PLX_CTRL_CLKACT_FIELD = 24
    PLX_CTRL_ODIV1_FIELD = slice(21, 16)
    PLX_CTRL_ODIV0_FIELD = slice(13, 8)
    PLX_CTRL_SRC_FIELD = slice(2, 0)

    PLX_CTRL_SRC_DEFAULT = 0

    PL_CLK_SRC_FIELD = PLX_CTRL_SRC_FIELD
    PL_CLK_ODIV0_FIELD = PLX_CTRL_ODIV0_FIELD
    PL_CLK_ODIV1_FIELD = PLX_CTRL_ODIV1_FIELD

    # Registers in the CRF "Namespace"
    CRF_APB_ADDRESS = 0xFD1A0000
    APLL_CTRL_OFFSET = 0x20
    DPLL_CTRL_OFFSET = 0x2C
    VPLL_CTRL_OFFSET = 0x38

    ACPU_CTRL_OFFSET = 0x60
    ACPU_CTRL_CLKHALF_FIELD = 25
    ACPU_CTRL_CLKFULL_FIELD = 24
    ACPU_CTRL_ODIV_FIELD = slice(13, 8)
    ACPU_CTRL_SRC_FIELD = slice(2, 0)
    

    # Fields shared between CRF and CRL "Namespaces"
    CRX_APB_SRC_DEFAULT = 0
    CRX_APB_SRC_FIELD = slice(22, 20)
    CRX_APB_ODIVBY2_FIELD = 16
    CRX_APB_FBDIV_FIELD = slice(14, 8)

    PLX_CTRL_ODIV1_WIDTH = (PLX_CTRL_ODIV1_FIELD.start -
                            PLX_CTRL_ODIV1_FIELD.stop + 1)
    PLX_CTRL_ODIV0_WIDTH = (PLX_CTRL_ODIV0_FIELD.start -
                            PLX_CTRL_ODIV0_FIELD.stop + 1)
    VALID_CLOCK_DIV_PRODUCTS = sorted(list(set(
        (np.multiply(
            np.arange(1 << PLX_CTRL_ODIV1_WIDTH)
            .reshape(1 << PLX_CTRL_ODIV1_WIDTH, 1),
            np.arange(1 << PLX_CTRL_ODIV0_WIDTH))).reshape(-1))))

    if CPU_ARCH_IS_SUPPORTED:
        IOPLL_CTRL = Register(CRL_APB_ADDRESS + IOPLL_CTRL_OFFSET)
        RPLL_CTRL = Register(CRL_APB_ADDRESS + RPLL_CTRL_OFFSET)

        PL_CLK_CTRLS = [Register(CRL_APB_ADDRESS + PL0_CTRL_OFFSET), 
                        Register(CRL_APB_ADDRESS + PL1_CTRL_OFFSET), 
                        Register(CRL_APB_ADDRESS + PL2_CTRL_OFFSET), 
                        Register(CRL_APB_ADDRESS + PL3_CTRL_OFFSET) ]

        ACPU_CTRL = Register(CRF_APB_ADDRESS + ACPU_CTRL_OFFSET)
        
        APLL_CTRL = Register(CRF_APB_ADDRESS + APLL_CTRL_OFFSET)
        DPLL_CTRL = Register(CRF_APB_ADDRESS + DPLL_CTRL_OFFSET)
        VPLL_CTRL = Register(CRF_APB_ADDRESS + VPLL_CTRL_OFFSET)

        PL_SRC_PLL_CTRLS = [IOPLL_CTRL, IOPLL_CTRL, RPLL_CTRL, DPLL_CTRL]
        ACPU_SRC_PLL_CTRLS = [APLL_CTRL, APLL_CTRL, DPLL_CTRL, VPLL_CTRL]
    else:
        warnings.warn("Pynq does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)
        
    @classmethod
    def set_pl_clk(cls, clk_idx, div0=None, div1=None, \
                       clk_mhz=DEFAULT_PL_CLK_MHZ):
        """This method sets a PL clock frequency.

        Users have to specify the index of the PL clock to be changed.
        For example, for fclk1 (Zynq) or pl1_clk (ZynqUltrascale), 
        `clk_idx` is 1.

        The CPU, and other source clocks, by default, should not get changed.

        Users have two options:
        1. specify the two frequency divider values directly (div0, div1), or
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
        try:
            pl_clk_reg = cls.PL_CLK_CTRLS[clk_idx]
        except:
            raise ValueError("Valid PL clock index is 0 - 3.")
        
        pl_clk_reg = cls.PL_CLK_CTRLS[clk_idx]

        pl_clk_reg[cls.PLX_CTRL_CLKACT_FIELD] = 1
        pl_clk_reg[cls.PLX_CTRL_SRC_FIELD] = cls.PLX_CTRL_SRC_DEFAULT
        super(_ClocksUltrascale, cls).set_pl_clk(clk_idx, div0, div1, clk_mhz)

    @classmethod
    def _get_pll_mhz(cls, pll_reg):
        """The getter method for PLL output clocks.

        Parameters
        ----------
        pll_reg : Register
            The control register for a PLL

        Returns
        -------
        float
            The PLL output clock rate measured in MHz.

        """
        if(pll_reg[cls.CRX_APB_SRC_FIELD] != cls.CRX_APB_SRC_DEFAULT):
            raise ValueError("Invalid PLL Source")

        pll_fbdiv = pll_reg[cls.CRX_APB_FBDIV_FIELD]
        if(pll_reg[cls.CRX_APB_ODIVBY2_FIELD] == 1):
            pll_odiv2 = 2
        else:
            pll_odiv2 = 1

        return cls.DEFAULT_SRC_CLK_MHZ * pll_fbdiv / pll_odiv2;
            
    @classmethod
    def _cpu_mhz(cls):
        """The getter method for CPU clock.

        The returned clock rate is measured in MHz.

        """
        arm_src_pll_idx = cls.ACPU_CTRL[cls.ACPU_CTRL_SRC_FIELD]
        arm_clk_odiv = cls.ACPU_CTRL[cls.ACPU_CTRL_ODIV_FIELD]
        src_pll_reg = cls.ACPU_SRC_PLL_CTRLS[arm_src_pll_idx]
        return round(cls._get_pll_mhz(src_pll_reg) / arm_clk_odiv, 6)

class _ClocksZynq(_Clocks):
    """Implementation class for all Zynq 7-Series PS and PL clocks
    not exposed to users.

    Since this is the abstract base class for all Zynq 7-Series clocks, no 
    attributes or methods are exposed to users. Users should use the class 
    `Clocks` instead.

    """
    DEFAULT_SRC_CLK_MHZ = 50.0

    SLCR_BASE_ADDRESS = 0xF8000000
    ARM_PLL_CTRL_OFFSET = 0x100
    DDR_PLL_CTRL_OFFSET = 0x104
    IO_PLL_CTRL_OFFSET = 0x108
    SRC_PLL_FBDIV_FIELD = slice(18, 12)

    FCLK0_CTRL_OFFSET = 0x170
    FCLK1_CTRL_OFFSET = 0x180
    FCLK2_CTRL_OFFSET = 0x190
    FCLK3_CTRL_OFFSET = 0x1A0
    FCLKX_CTRL_ODIV1_FIELD = slice(25, 20)
    FCLKX_CTRL_ODIV0_FIELD = slice(13, 8)
    FCLKX_CTRL_SRC_FIELD = slice(5, 4)

    PL_CLK_SRC_FIELD = FCLKX_CTRL_SRC_FIELD
    PL_CLK_ODIV0_FIELD = FCLKX_CTRL_ODIV0_FIELD
    PL_CLK_ODIV1_FIELD = FCLKX_CTRL_ODIV1_FIELD

    ARM_CLK_CTRL_OFFSET = 0x120
    ARM_CLK_ODIV_FIELD = slice(13, 8)
    ARM_CLK_SRC_FIELD = slice(5, 4)

    FCLKX_CTRL_ODIV1_WIDTH = (FCLKX_CTRL_ODIV1_FIELD.start -
                              FCLKX_CTRL_ODIV1_FIELD.stop + 1)
    FCLKX_CTRL_ODIV0_WIDTH = (FCLKX_CTRL_ODIV0_FIELD.start -
                              FCLKX_CTRL_ODIV0_FIELD.stop + 1)
    VALID_CLOCK_DIV_PRODUCTS = sorted(list(set(
        (np.multiply(
            np.arange(1 << FCLKX_CTRL_ODIV1_WIDTH)
            .reshape(1 << FCLKX_CTRL_ODIV1_WIDTH, 1),
            np.arange(1 << FCLKX_CTRL_ODIV0_WIDTH))).reshape(-1))))

    if CPU_ARCH_IS_SUPPORTED:
        ARM_PLL_CTRL = Register(SLCR_BASE_ADDRESS + ARM_PLL_CTRL_OFFSET)
        DDR_PLL_CTRL = Register(SLCR_BASE_ADDRESS + DDR_PLL_CTRL_OFFSET)
        IO_PLL_CTRL = Register(SLCR_BASE_ADDRESS + IO_PLL_CTRL_OFFSET)

        PL_SRC_PLL_CTRLS = [IO_PLL_CTRL, IO_PLL_CTRL, 
                            ARM_PLL_CTRL, DDR_PLL_CTRL]

        PL_CLK_CTRLS = [Register(SLCR_BASE_ADDRESS + FCLK0_CTRL_OFFSET), 
                        Register(SLCR_BASE_ADDRESS + FCLK1_CTRL_OFFSET), 
                        Register(SLCR_BASE_ADDRESS + FCLK2_CTRL_OFFSET), 
                        Register(SLCR_BASE_ADDRESS + FCLK3_CTRL_OFFSET) ]

        ARM_CLK_CTRL = Register(SLCR_BASE_ADDRESS + ARM_CLK_CTRL_OFFSET)

        ARM_SRC_PLL_CTRLS = [ARM_PLL_CTRL, ARM_PLL_CTRL, 
                             DDR_PLL_CTRL, IO_PLL_CTRL]
    else:
        warnings.warn("Pynq does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)
        
    @classmethod
    def _get_pll_mhz(cls, pll_reg):
        """The getter method for PLL output clocks.

        Parameters
        ----------
        pll_reg : Register
            The control register for a PLL

        Returns
        -------
        float
            The PLL output clock rate measured in MHz.

        """
        pll_fbdiv = pll_reg[cls.SRC_PLL_FBDIV_FIELD]
        clk_mhz = cls.DEFAULT_SRC_CLK_MHZ * pll_fbdiv

        return round(clk_mhz, 6)

    @classmethod
    def _cpu_mhz(cls):
        """The getter method for the CPU clock.

        Returns
        -------
        float
            The CPU clock rate measured in MHz.

        """
        arm_src_pll_idx = cls.ARM_CLK_CTRL[cls.ARM_CLK_SRC_FIELD]
        arm_clk_odiv = cls.ARM_CLK_CTRL[cls.ARM_CLK_ODIV_FIELD]
        src_pll_reg = cls.ARM_SRC_PLL_CTRLS[arm_src_pll_idx]
        
        return round(cls._get_pll_mhz(src_pll_reg) / arm_clk_odiv, 6)

class Clocks(_ClocksUltrascale if CPU_ARCH == ZU_ARCH \
                 else _ClocksZynq, \
                 metaclass=_Clocks):
    """Class for all the PS and PL clocks exposed to users.

    With this class, users can get the CPU clock and all the PL clocks. Users
    can also set PL clocks to other values using this class.

    Attributes
    ----------
    cpu_mhz : float
        The clock rate of the CPU, measured in MHz.
    pl_clk_0_mhz : float
        The clock rate of the PL clock 0, measured in MHz.
    pl_clk_1_mhz : float
        The clock rate of the PL clock 1, measured in MHz.
    pl_clk_2_mhz : float
        The clock rate of the PL clock 2, measured in MHz.
    pl_clk_3_mhz : float
        The clock rate of the PL clock 3, measured in MHz.
    debug : bool
        Print debug messages, if True
    """
    def __init__(self):
        """Return a new Clocks object.
        Parameters
        ----------
        debug : bool
            Turn on debug mode if it is True; default is False.

        Note
        ----

        This class requires root permissions.

        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')
