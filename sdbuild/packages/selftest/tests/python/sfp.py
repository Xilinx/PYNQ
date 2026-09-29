# Verify SFP 25G XXV Ethernet internal and external loopback DMA round-trip.
# Params: container, xxv_ip, dma_ip (overlay attribute path).

# p: manifest params dict for this test (from selftest.json "params").
import time

import numpy as np
import pynq

from board_helpers import overlay
from results import FailError, ok, main_entry


def _reset_gt(xxv):
    xxv.register_map.GT_RESET_REG = 0x01
    xxv.register_map.RESET_REG = 0x03
    xxv.register_map.GT_RESET_REG = 0x00
    xxv.register_map.RESET_REG = 0x00


def _sfp_loopback(xxv, dma, internal):
    xxv.register_map.MODE_REG.ctl_local_loopback = 1 if internal else 0
    if not internal:
        _reset_gt(xxv)
    time.sleep(2)
    payload = np.frombuffer(
        (b"PYNQ SFP 25G loopback self-test frame. " * 8)[:256],
        dtype=np.uint8,
    )
    tx = pynq.allocate(payload.shape[0], dtype=np.uint8)
    rx = pynq.allocate(payload.shape[0], dtype=np.uint8)
    tx[:] = payload
    try:
        dma.sendchannel.transfer(tx)
        dma.recvchannel.transfer(rx)
        dma.sendchannel.wait()
        dma.recvchannel.wait()
        if not np.array_equal(tx, rx):
            mode = "internal" if internal else "external"
            raise AssertionError("SFP %s loopback payload mismatch" % mode)
    finally:
        del tx, rx


def run(p=None):
    p = p or {}
    container = p.get("container")
    xxv_name = p.get("xxv_ip")
    dma_name = p.get("dma_ip")
    if not container or not xxv_name or not dma_name:
        raise FailError("manifest params.container, xxv_ip, dma_ip required")

    base = overlay()
    try:
        block = getattr(base, container)
        xxv = getattr(block, xxv_name)
        dma = getattr(block, dma_name)
    except AttributeError:
        raise FailError("%s.%s / %s.%s not in overlay" % (container, xxv_name, container, dma_name))

    _sfp_loopback(xxv, dma, internal=True)
    ok("SFP 25G XXV internal loopback DMA round-trip matched")

    _sfp_loopback(xxv, dma, internal=False)
    ok("SFP 25G XXV external loopback DMA round-trip matched (SFP loopback module)")


if __name__ == "__main__":
    main_entry(run)
