# Verify AXI DMA loopback transfers match sent data.
# Params: bitstream.

import numpy as np

from board_helpers import overlay
from results import FailError, bad, ok, main_entry
from pynq import allocate


def run(p=None):
    p = p or {}
    bit = p.get("bitstream")
    base = overlay(bit)
    try:
        dma = base.dma
    except AttributeError:
        raise FailError("dma not in overlay")
    dma.reset()
    n = 1024
    tx = allocate(shape=(n,), dtype=np.uint32)
    rx = allocate(shape=(n,), dtype=np.uint32)
    try:
        tx[:] = np.arange(n, dtype=np.uint32)
        rx[:] = 0
        dma.sendchannel.transfer(tx)
        dma.recvchannel.transfer(rx)
        dma.sendchannel.wait()
        dma.recvchannel.wait()
        if np.array_equal(tx, rx):
            ok("DMA loopback recovered %d x uint32 (%d bytes)" % (n, n * 4))
        else:
            nbad = int(np.count_nonzero(tx != rx))
            bad("DMA loopback mismatch: %d/%d words differ" % (nbad, n))
    finally:
        tx.freebuffer()
        rx.freebuffer()


if __name__ == "__main__":
    main_entry(run)
