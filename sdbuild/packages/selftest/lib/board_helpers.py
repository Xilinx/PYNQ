"""Shared helpers for board-specific overlay tests."""

import os

_state = {"base": None, "rf_clks": False}


def overlay(bitstream=None):
    if _state["base"] is None:
        from pynq.overlays.base import BaseOverlay

        bit = bitstream or os.environ.get("SELFTEST_BITSTREAM", "base.bit")
        _state["base"] = BaseOverlay(bit)
    return _state["base"]


def init_rf_clks(base=None):
    if not _state["rf_clks"]:
        base = base or overlay()
        base.init_rf_clks()
        _state["rf_clks"] = True


def free_iop(iop):
    from pynq import PL

    info = iop.mb_info if hasattr(iop, "mb_info") else iop
    ip = info.get("ip_name")
    if ip in PL.mem_dict:
        PL.mem_dict[ip]["state"] = None
