#   Copyright (C) 2026 Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

from pynqmetadata import UltrascaleProcSysCore, VersalProcSysCore, ZynqProcSysCore

from pynq import ps


ZU_FPD_SLCR_REG = {
    "C_MAXIGP0_DATA_WIDTH": {
        "FPD_SLCR.AXI_FS.DW_SS0_SEL": {"addr": 0xFD615000, "field": [9, 8]}
    },
    "C_MAXIGP1_DATA_WIDTH": {
        "FPD_SLCR.AXI_FS.DW_SS1_SEL": {"addr": 0xFD615000, "field": [11, 10]}
    },
    "C_MAXIGP2_DATA_WIDTH": {
        "LPD_SLCR.AXI_FS.DW_SS2_SEL": {"addr": 0xFF419000, "field": [9, 8]}
    },
}

ZU_FPD_SLCR_VALUE = {"32": 0, "64": 1, "128": 2}

ZU_AXIFM_REG = {
    "C_SAXIGP0_DATA_WIDTH": {
        "AFIFM0.AFIFM_RDCTRL.FABRIC_WIDTH": {"addr": 0xFD360000, "field": [1, 0]},
        "AFIFM0.AFIFM_WRCTRL.FABRIC_WIDTH": {"addr": 0xFD360014, "field": [1, 0]},
    },
    "C_SAXIGP1_DATA_WIDTH": {
        "AFIFM1.AFIFM_RDCTRL.FABRIC_WIDTH": {"addr": 0xFD370000, "field": [1, 0]},
        "AFIFM1.AFIFM_WRCTRL.FABRIC_WIDTH": {"addr": 0xFD370014, "field": [1, 0]},
    },
    "C_SAXIGP2_DATA_WIDTH": {
        "AFIFM2.AFIFM_RDCTRL.FABRIC_WIDTH": {"addr": 0xFD380000, "field": [1, 0]},
        "AFIFM2.AFIFM_WRCTRL.FABRIC_WIDTH": {"addr": 0xFD380014, "field": [1, 0]},
    },
    "C_SAXIGP3_DATA_WIDTH": {
        "AFIFM3.AFIFM_RDCTRL.FABRIC_WIDTH": {"addr": 0xFD390000, "field": [1, 0]},
        "AFIFM3.AFIFM_WRCTRL.FABRIC_WIDTH": {"addr": 0xFD390014, "field": [1, 0]},
    },
    "C_SAXIGP4_DATA_WIDTH": {
        "AFIFM4.AFIFM_RDCTRL.FABRIC_WIDTH": {"addr": 0xFD3A0000, "field": [1, 0]},
        "AFIFM4.AFIFM_WRCTRL.FABRIC_WIDTH": {"addr": 0xFD3A0014, "field": [1, 0]},
    },
    "C_SAXIGP5_DATA_WIDTH": {
        "AFIFM5.AFIFM_RDCTRL.FABRIC_WIDTH": {"addr": 0xFD3B0000, "field": [1, 0]},
        "AFIFM5.AFIFM_WRCTRL.FABRIC_WIDTH": {"addr": 0xFD3B0014, "field": [1, 0]},
    },
    "C_SAXIGP6_DATA_WIDTH": {
        "AFIFM6.AFIFM_RDCTRL.FABRIC_WIDTH": {"addr": 0xFF9B0000, "field": [1, 0]},
        "AFIFM6.AFIFM_WRCTRL.FABRIC_WIDTH": {"addr": 0xFF9B0014, "field": [1, 0]},
    },
}

ZU_AXIFM_VALUE = {"32": 2, "64": 1, "128": 0}


class ZynqArch:
    """Architecture of Zynq-7000 SoCs"""

    _GPIO_MIN_USER_PIN = 54
    _clocks_class = ps._ClocksZynq
    _ps_core = ZynqProcSysCore


class ZynqUltrascaleArch:
    """Architecture of Zynq UltraScale+ MPSoCs and RFSoCs"""

    _GPIO_MIN_USER_PIN = 78
    _clocks_class = ps._ClocksUltrascale
    _ps_core = UltrascaleProcSysCore

    def set_axi_port_width(self, parser):
        """This method will set the AXI port width.

        This is useful to resolve discrepancy between the PS configurations
        during boot and the PS configurations required by the bitstream. It
        is usually to be resolved for full bitstream reconfiguration.

        Check https://adaptivesupport.amd.com/s/article/66295 for more
        information on the meaning of register values.

        Currently only zynq ultrascale devices support data width changes.

        """
        from pynq.registers import Register

        if not hasattr(parser, "ps_name"):
            # Setting port widths not supported for xclbin-only designs
            return
        parameter_dict = parser.ip_dict[parser.ps_name]["parameters"]
        if parser.family_ps == "zynq_ultra_ps_e":
            for para in ZU_FPD_SLCR_REG:
                if para in parameter_dict:
                    width = parameter_dict[para]
                    for reg_name in ZU_FPD_SLCR_REG[para]:
                        addr = ZU_FPD_SLCR_REG[para][reg_name]["addr"]
                        f = ZU_FPD_SLCR_REG[para][reg_name]["field"]
                        Register(addr, device=self)[f[0] : f[1]] = ZU_FPD_SLCR_VALUE[width]
            for para in ZU_AXIFM_REG:
                if para in parameter_dict:
                    width = parameter_dict[para]
                    for reg_name in ZU_AXIFM_REG[para]:
                        addr = ZU_AXIFM_REG[para][reg_name]["addr"]
                        f = ZU_AXIFM_REG[para][reg_name]["field"]
                        Register(addr, device=self)[f[0] : f[1]] = ZU_AXIFM_VALUE[width]


class VersalArch:
    """Architecture of Versal adaptive SoCs"""

    _GPIO_MIN_USER_PIN = {'versal_gpio': 26, 'pmc_gpio': 52}
    _clocks_class = ps._ClocksVersal
    _ps_core = VersalProcSysCore


def _arch_class(device=None):
    """Return the architecture class of `device`, or of this machine if None"""
    arch = ps.CPU_ARCH if device is None else device.arch
    if arch == ps.ZU_ARCH and ps._is_versal(device):
        return VersalArch
    return {ps.ZYNQ_ARCH: ZynqArch, ps.ZU_ARCH: ZynqUltrascaleArch}.get(arch)
