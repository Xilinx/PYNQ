# Verify overlay loads and allocate() succeeds.
# Params: bitstream (default base.bit).

import numpy as np

from results import bad, ok, params, main_entry


def run(p=None):
    p = p or {}
    bit = p.get("bitstream", "base.bit")
    from pynq import Overlay, allocate

    base = Overlay(bit)
    if not base.is_loaded():
        bad("Overlay('%s') did not load the PL" % bit)
        return
    if not base.ip_dict:
        bad("Overlay('%s') loaded but ip_dict is empty" % bit)
        return

    buf = allocate(shape=(1024,), dtype=np.uint32)
    try:
        buf[:] = np.arange(1024)
        buf.flush()
        _ = buf.device_address
    finally:
        buf.freebuffer()
    ok("Overlay('%s') loaded (%d IPs) + allocate() succeeded" % (bit, len(base.ip_dict)))


if __name__ == "__main__":
    main_entry(run)
