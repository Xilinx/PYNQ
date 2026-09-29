# Verify CMAC 100G internal and external (QSFP) loopback DMA through overlay cmac/dma IPs.

# p: manifest params dict for this test (from selftest.json "params").
import time

import numpy as np

from board_helpers import overlay
from results import FailError, ok, main_entry

CMAC_ALIGN_TIMEOUT_S = 8


def _cmac_loopback(internal):
    base = overlay()
    from pynq import allocate

    try:
        cmac = base.cmac
        dma = base.dma
    except AttributeError:
        raise FailError("cmac / dma not in overlay")
    cmac.internal_loopback = 1 if internal else 0
    if not internal:
        cmac.reset(gt=1)
        time.sleep(1)
    cmac.register_map.conf_rx = 1
    cmac.register_map.conf_tx = 0x10
    deadline = time.time() + CMAC_ALIGN_TIMEOUT_S
    aligned = False
    while time.time() < deadline:
        if cmac.register_map.stat_rx_status[1]:
            aligned = True
            break
        time.sleep(0.1)
    if not aligned:
        mode = "internal" if internal else "external"
        raise FailError(
            "CMAC RX never aligned in %s loopback%s"
            % (
                mode,
                "" if internal else " -- attach a QSFP loopback module",
            )
        )
    cmac.register_map.conf_tx = 1
    payload = np.frombuffer(
        (b"PYNQ CMAC 100G loopback self-test frame. " * 8)[:256],
        dtype=np.uint8,
    )
    tx = allocate(payload.shape[0], dtype=np.uint8)
    rx = allocate(payload.shape[0], dtype=np.uint8)
    tx[:] = payload
    try:
        dma.recvchannel.transfer(rx)
        dma.sendchannel.transfer(tx)
        dma.sendchannel.wait()
        dma.recvchannel.wait()
        if not np.array_equal(tx, rx):
            raise AssertionError("CMAC loopback payload mismatch")
    finally:
        del tx, rx


def run(p=None):
    _cmac_loopback(internal=True)
    ok("CMAC 100G internal-loopback DMA round-trip matched")

    _cmac_loopback(internal=False)
    ok("CMAC 100G external-loopback DMA round-trip matched (QSFP loopback module)")


if __name__ == "__main__":
    main_entry(run)
