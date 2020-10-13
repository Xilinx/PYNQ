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

import os
import warnings

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"

ZYNQ_ARCH = "armv7l"
ZU_ARCH = "aarch64"
CPU_ARCH = os.uname().machine
CPU_ARCH_IS_SUPPORTED = CPU_ARCH in [ZYNQ_ARCH, ZU_ARCH]

DEFAULT_PL_CLK_MHZ = 100.0

ZYNQ_PLL_FIELDS = {
    'PLL_FDIV': {'access': 'read-write', 'bit_offset': 12, 'bit_width': 7,
                 'description': 'Provide the feedback divisor for the PLL'},
}

ZYNQ_ARM_FIELDS = {
    'DIVISOR': {'access': 'read-write', 'bit_offset': 8, 'bit_width': 6,
                'description': 'Frequency divisor for the CPU clock'},
    'SRCSEL': {'access': 'read-write', 'bit_offset': 4, 'bit_width': 2,
               'description': 'Source for the CPU clock'}
}

ZYNQ_CLK_FIELDS = {
    'DIVISOR1': {'access': 'read-write', 'bit_offset': 20, 'bit_width': 6,
                 'description': 'Second divisor of the clock source'},
    'DIVISOR0': {'access': 'read-write', 'bit_offset': 8, 'bit_width': 6,
                 'description': 'First divisor of the clock source'},
    'SRCSEL': {'access': 'read-write', 'bit_offset': 4, 'bit_width': 2,
               'description': 'Select the source for the clock'},
}

ZYNQ_SLCR_REGISTERS = {
    'ARM_PLL_CTRL': {'address_offset': 0x100, 'access': 'read-write',
                     'size': 32, 'description': 'ARM PLL Control',
                     'fields': ZYNQ_PLL_FIELDS},
    'DDR_PLL_CTRL': {'address_offset': 0x104, 'access': 'read-write',
                     'size': 32, 'description': 'DDR PLL Control',
                     'fields': ZYNQ_PLL_FIELDS},
    'IO_PLL_CTRL': {'address_offset': 0x108, 'access': 'read-write',
                    'size': 32, 'description': 'IO PLL Control',
                    'fields': ZYNQ_PLL_FIELDS},
    'ARM_CLK_CTRL': {'address_offset': 0x120, 'access': 'read-write',
                     'size': 32, 'description': 'CPU Clock Control',
                     'fields': ZYNQ_ARM_FIELDS},
    'FPGA0_CLK_CTRL': {'address_offset': 0x170, 'access': 'read-write',
                       'size': 32, 'description': 'PL Clock 0 Control',
                       'fields': ZYNQ_CLK_FIELDS},
    'FPGA1_CLK_CTRL': {'address_offset': 0x180, 'access': 'read-write',
                       'size': 32, 'description': 'PL Clock 1 Control',
                       'fields': ZYNQ_CLK_FIELDS},
    'FPGA2_CLK_CTRL': {'address_offset': 0x190, 'access': 'read-write',
                       'size': 32, 'description': 'PL Clock 2 Control',
                       'fields': ZYNQ_CLK_FIELDS},
    'FPGA3_CLK_CTRL': {'address_offset': 0x1a0, 'access': 'read-write',
                       'size': 32, 'description': 'PL Clock 3 Control',
                       'fields': ZYNQ_CLK_FIELDS},
}

ZU_PLL_FIELDS = {
    'PRE_SRC': {'access': 'read-write', 'bit_offset': 20, 'bit_width': 3,
                'description': 'Select the clock source for the PLL input'},
    'DIV2': {'access': 'read-write', 'bit_offset': 16, 'bit_width': 1,
             'description': 'Divide output frequency by 2'},
    'FBDIV': {'access': 'read-write', 'bit_offset': 8, 'bit_width': 7,
              'description': 'Feedback divisor for the PLL'}
}

ZU_CLK_FIELDS = {
    'CLKACT': {'access': 'read-write', 'bit_offset': 24, 'bit_width': 1,
               'description': 'Enable the clock output'},
    'DIVISOR1': {'access': 'read-write', 'bit_offset': 16, 'bit_width': 6,
                 'description': 'Second divisor of the clock source'},
    'DIVISOR0': {'access': 'read-write', 'bit_offset': 8, 'bit_width': 6,
                 'description': 'First divisor of the clock sourcer'},
    'SRCSEL': {'access': 'read-write', 'bit_offset': 0, 'bit_width': 3,
               'description': 'Clock generator input source'}
}

ZU_ARM_FIELDS = {
    'DIVISOR0': {'access': 'read-write', 'bit_offset': 8, 'bit_width': 6,
                 'description': 'First divisor of the clock sourcer'},
    'SRCSEL': {'access': 'read-write', 'bit_offset': 0, 'bit_width': 3,
               'description': 'Clock generator input source'}
}

ZU_CRL_REGISTERS = {
    'IOPLL_CTRL': {'address_offset': 0x20, 'access': 'read-write',
                   'size': 32, 'description': 'IOPLL Clock Unit Control',
                   'fields': ZU_PLL_FIELDS},
    'RPLL_CTRL': {'address_offset': 0x30, 'access': 'read-write',
                  'size': 32, 'description': 'RPLL Clock Unit Control',
                  'fields': ZU_PLL_FIELDS},
    'PL0_REF_CTRL': {'address_offset': 0xc0, 'access': 'read-write',
                     'size': 32, 'description': 'PL Clock 0 Control',
                     'fields': ZU_CLK_FIELDS},
    'PL1_REF_CTRL': {'address_offset': 0xc4, 'access': 'read-write',
                     'size': 32, 'description': 'PL Clock 1 Control',
                     'fields': ZU_CLK_FIELDS},
    'PL2_REF_CTRL': {'address_offset': 0xc8, 'access': 'read-write',
                     'size': 32, 'description': 'PL Clock 2 Control',
                     'fields': ZU_CLK_FIELDS},
    'PL3_REF_CTRL': {'address_offset': 0xcc, 'access': 'read-write',
                     'size': 32, 'description': 'PL Clock 3 Control',
                     'fields': ZU_CLK_FIELDS}
}

ZU_CRF_REGISTERS = {
    'APLL_CTRL': {'address_offset': 0x20, 'access': 'read-write',
                  'size': 32, 'description': 'APLL Clock Unit Control',
                  'fields': ZU_PLL_FIELDS},
    'DPLL_CTRL': {'address_offset': 0x2C, 'access': 'read-write',
                  'size': 32, 'description': 'DPLL Clock Unit Control',
                  'fields': ZU_PLL_FIELDS},
    'VPLL_CTRL': {'address_offset': 0x38, 'access': 'read-write',
                  'size': 32, 'description': 'VPLL Clock Unit Control',
                  'fields': ZU_PLL_FIELDS},
    'ACPU_CTRL': {'address_offset': 0x60, 'access': 'read-write',
                  'size': 32, 'description': 'CPU Clock Control',
                  'fields': ZU_ARM_FIELDS}
}


class _ClocksMeta(type):
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
        return cls._instance.get_cpu_mhz()

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
        return cls._instance.get_pl_clk(0)

    @fclk0_mhz.setter
    def fclk0_mhz(cls, clk_mhz):
        """The setter method for PL clock 0.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls._instance.set_pl_clk(0, clk_mhz=clk_mhz)

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
        return cls._instance.get_pl_clk(1)

    @fclk1_mhz.setter
    def fclk1_mhz(cls, clk_mhz):
        """The setter method for PL clock 1.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls._instance.set_pl_clk(1, clk_mhz=clk_mhz)

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
        return cls._instance.get_pl_clk(2)

    @fclk2_mhz.setter
    def fclk2_mhz(cls, clk_mhz):
        """The setter method for PL clock 2.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls._instance.set_pl_clk(2, clk_mhz=clk_mhz)

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
        return cls._instance.get_pl_clk(3)

    @fclk3_mhz.setter
    def fclk3_mhz(cls, clk_mhz):
        """The setter method for PL clock 3.

        Parameters
        ----------
        clk_mhz : float
            The clock rate in MHz.

        """
        cls._instance.set_pl_clk(3, clk_mhz=clk_mhz)

    def get_pl_clk(cls, clk_idx):
        """This method will return the clock frequency.

        This method is not exposed to users.

        Parameters
        ----------
        clk_idx : int
            The index of the PL clock to be changed, from 0 to 3.

        """
        cls._instance.get_pl_clk(clk_idx)

    def set_pl_clk(cls, clk_idx, div0=None, div1=None,
                   clk_mhz=DEFAULT_PL_CLK_MHZ):
        """This method sets a PL clock frequency.

        Users have to specify the index of the PL clock to be changed.
        For example, for fclk1 (Zynq) or pl_clk_1 (ZynqUltrascale),
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
        cls._instance.set_pl_clk(clk_idx, div0, div1, clk_mhz)

    @property
    def _instance(cls):
        if not hasattr(cls, '_real_instance'):
            if CPU_ARCH == ZYNQ_ARCH:
                cls._real_instance = _ClocksZynq()
            elif CPU_ARCH == ZU_ARCH:
                cls._real_instance = _ClocksUltrascale()
            else:
                raise RuntimeError('Architecture not supported for Clocks')
        return cls._real_instance


class _ClocksBase:

    def get_pl_clk(self, clk_idx):
        """This method will return the clock frequency.

        This method is not exposed to users.

        Parameters
        ----------
        clk_idx : int
            The index of the PL clock to be changed, from 0 to 3.

        """
        if clk_idx not in range(4):
            raise ValueError("Valid PL clock index is 0 - 3.")

        pl_clk_reg = self.PL_CLK_CTRLS[clk_idx]
        src_clk_idx = pl_clk_reg.SRCSEL
        src_clk_mhz = self._get_src_clk_mhz(src_clk_idx)
        pl_clk_odiv0 = pl_clk_reg.DIVISOR0
        pl_clk_odiv1 = pl_clk_reg.DIVISOR1

        return round(src_clk_mhz / (pl_clk_odiv0 * pl_clk_odiv1), 6)

    def set_pl_clk(self, clk_idx, div0=None, div1=None,
                   clk_mhz=DEFAULT_PL_CLK_MHZ):
        """This method sets a PL clock frequency.

        Users have to specify the index of the PL clock to be changed.
        For example, for fclk1 (Zynq) or pl_clk_1 (ZynqUltrascale),
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
        if clk_idx not in range(4):
            raise ValueError("Valid PL clock index is 0 - 3.")

        pl_clk_reg = self.PL_CLK_CTRLS[clk_idx]
        div0_width = 6
        div1_width = 6
        src_clk_idx = pl_clk_reg.SRCSEL
        src_clk_mhz = self._get_src_clk_mhz(src_clk_idx)

        if div0 is None and div1 is None:
            div0, div1 = self._get_2_divisors(src_clk_mhz, clk_mhz,
                                              div0_width, div1_width)
        elif div0 is not None and div1 is None:
            div1 = round(src_clk_mhz / clk_mhz / div0)
        elif div1 is not None and div0 is None:
            div0 = round(src_clk_mhz / clk_mhz / div1)

        if div0 <= 0 or div0 > ((1 << div0_width) - 1):
            raise ValueError("Frequency divider 0 value out of range.")
        if div1 <= 0 or div1 > ((1 << div1_width) - 1):
            raise ValueError("Frequency divider 1 value out of range.")

        pl_clk_reg.DIVISOR0 = div0
        pl_clk_reg.DIVISOR1 = div1

    def _get_src_clk_mhz(self, clk_idx):
        """The getter method for PL clock (pl_clk) sources.

        The returned clock rate is measured in MHz.

        """
        src_pll_reg = self.PL_SRC_PLL_CTRLS[clk_idx]
        return round(self.get_pll_mhz(src_pll_reg), 6)

    def _get_2_divisors(self, freq_high, freq_desired, reg0_width, reg1_width):
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
        _, q0 = min(enumerate(self.VALID_CLOCK_DIV_PRODUCTS.keys()),
                    key=lambda x: abs(x[1] - div_product_desired))
        if abs(freq_desired - freq_high / q0) > 0.01 * freq_desired:
            warnings.warn(
                "Setting frequency to the closest possible value {}MHz.".format(
                    round(freq_high / q0, 5)))
        return self.VALID_CLOCK_DIV_PRODUCTS[q0]


class _ClocksUltrascale(_ClocksBase):
    """Implementation class for all Zynq Ultrascale PS and PL clocks
    not exposed to users.

    Since this is the abstract base class for all Zynq Ultrascale clocks, no
    attributes or methods are exposed to users. Users should use the class
    `Clocks` instead.

    """
    DEFAULT_SRC_CLK_MHZ = 33.333
    CRL_APB_ADDRESS = 0xFF5E0000
    CRF_APB_ADDRESS = 0xFD1A0000
    CRX_APB_SRC_DEFAULT = 0
    PLX_CTRL_SRC_DEFAULT = 0

    VALID_CLOCK_DIV_PRODUCTS = {i*j: (i, j)
                                for i in range(1 << 6)
                                for j in range(1 << 6)}

    def __init__(self, src_clk_mhz=33.333):
        self._ref_clk_mhz = src_clk_mhz

        from .mmio import MMIO
        self._crf_mmio = MMIO(self.CRF_APB_ADDRESS, 0x100)
        self._crl_mmio = MMIO(self.CRL_APB_ADDRESS, 0x100)

        from .registers import RegisterMap
        CrfRegisterMap = RegisterMap.create_subclass('CRF', ZU_CRF_REGISTERS)
        CrlRegisterMap = RegisterMap.create_subclass('CRL', ZU_CRL_REGISTERS)

        self._crf_registers = CrfRegisterMap(self._crf_mmio.array)
        self._crl_registers = CrlRegisterMap(self._crl_mmio.array)

        self.PL_CLK_CTRLS = [
            self._crl_registers.PL0_REF_CTRL, self._crl_registers.PL1_REF_CTRL,
            self._crl_registers.PL2_REF_CTRL, self._crl_registers.PL3_REF_CTRL
        ]

        self.PL_SRC_PLL_CTRLS = [
            self._crl_registers.IOPLL_CTRL, None,
            self._crl_registers.RPLL_CTRL, self._crf_registers.DPLL_CTRL
        ]

        self.ACPU_SRC_PLL_CTRLS = [
            self._crf_registers.APLL_CTRL, None,
            self._crf_registers.DPLL_CTRL, self._crf_registers.VPLL_CTRL
        ]

    def set_pl_clk(self, clk_idx, div0=None, div1=None,
                   clk_mhz=DEFAULT_PL_CLK_MHZ):
        """This method sets a PL clock frequency.

        Users have to specify the index of the PL clock to be changed.

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
        pl_clk_reg = self.PL_CLK_CTRLS[clk_idx]
        pl_clk_reg.CLKACT = 1
        pl_clk_reg.SRC_FIELD = self.PLX_CTRL_SRC_DEFAULT
        super().set_pl_clk(clk_idx, div0, div1, clk_mhz)

    def get_pll_mhz(self, pll_reg):
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
        if pll_reg.PRE_SRC != self.CRX_APB_SRC_DEFAULT:
            raise ValueError("Invalid PLL Source")

        pll_fbdiv = pll_reg.FBDIV
        if pll_reg.DIV2:
            pll_odiv2 = 2
        else:
            pll_odiv2 = 1

        return self._ref_clk_mhz * pll_fbdiv / pll_odiv2

    def get_cpu_mhz(self):
        """The getter method for CPU clock.

        The returned clock rate is measured in MHz.

        """
        acpu_reg = self._crf_registers.ACPU_CTRL
        arm_src_pll_idx = acpu_reg.SRCSEL
        arm_clk_odiv = acpu_reg.DIVISOR0
        src_pll_reg = self.ACPU_SRC_PLL_CTRLS[arm_src_pll_idx]
        return round(self.get_pll_mhz(src_pll_reg) / arm_clk_odiv, 6)


class _ClocksZynq(_ClocksBase):
    """Implementation class for all Zynq 7-Series PS and PL clocks
    not exposed to users.

    Since this is the abstract base class for all Zynq 7-Series clocks, no
    attributes or methods are exposed to users. Users should use the class
    `Clocks` instead.

    """
    DEFAULT_SRC_CLK_MHZ = 50.0
    SLCR_BASE_ADDRESS = 0xF8000000

    VALID_CLOCK_DIV_PRODUCTS = {i*j: (i, j)
                                for i in range(1 << 6)
                                for j in range(1 << 6)}

    def __init__(self, ref_clk_mhz=50.0):
        self._ref_clk_mhz = ref_clk_mhz

        from .mmio import MMIO
        self._slcr_mmio = MMIO(self.SLCR_BASE_ADDRESS, 0x200)

        from .registers import RegisterMap
        SlcrRegisters = RegisterMap.create_subclass('SL', ZYNQ_SLCR_REGISTERS)
        self._slcr_registers = SlcrRegisters(self._slcr_mmio.array)

        self.PL_CLK_CTRLS = [
            self._slcr_registers.FPGA0_CLK_CTRL,
            self._slcr_registers.FPGA1_CLK_CTRL,
            self._slcr_registers.FPGA2_CLK_CTRL,
            self._slcr_registers.FPGA3_CLK_CTRL
        ]

        self.PL_SRC_PLL_CTRLS = [
            self._slcr_registers.IO_PLL_CTRL,
            self._slcr_registers.IO_PLL_CTRL,
            self._slcr_registers.ARM_PLL_CTRL,
            self._slcr_registers.DDR_PLL_CTRL,
        ]

        self.ARM_SRC_PLL_CTRLS = [
            self._slcr_registers.ARM_PLL_CTRL,
            self._slcr_registers.ARM_PLL_CTRL,
            self._slcr_registers.DDR_PLL_CTRL,
            self._slcr_registers.IO_PLL_CTRL,
        ]

    def set_pl_clk(self, clk_idx, div0=None, div1=None,
                   clk_mhz=DEFAULT_PL_CLK_MHZ):
        """This method sets a PL clock frequency.

        Users have to specify the index of the PL clock to be changed.

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
        super().set_pl_clk(clk_idx, div0, div1, clk_mhz)

    def get_pll_mhz(self, pll_reg):
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
        pll_fbdiv = pll_reg.PLL_FDIV
        clk_mhz = self._ref_clk_mhz * pll_fbdiv

        return round(clk_mhz, 6)

    def get_cpu_mhz(self):
        """The getter method for the CPU clock.

        Returns
        -------
        float
            The CPU clock rate measured in MHz.

        """
        cpu_ctrl_reg = self._slcr_registers.ARM_CLK_CTRL
        arm_src_pll_idx = cpu_ctrl_reg.SRCSEL
        arm_clk_odiv = cpu_ctrl_reg.DIVISOR
        src_pll_reg = self.ARM_SRC_PLL_CTRLS[arm_src_pll_idx]
        return round(self.get_pll_mhz(src_pll_reg) / arm_clk_odiv, 6)


class Clocks(metaclass=_ClocksMeta):
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
    pass
