# Verify PYNQ allocate() can create a DMA buffer without loading an overlay.

# p: manifest params dict for this test (from selftest.json "params").
import numpy as np

from results import ok, main_entry


def run(p=None):
    from pynq import allocate

    buf = allocate(shape=(1024,), dtype=np.uint32)
    try:
        buf[:] = np.arange(1024)
        buf.flush()
        _ = buf.device_address
    finally:
        buf.freebuffer()
    ok("allocate() DMA buffer flush + device_address succeeded")


if __name__ == "__main__":
    main_entry(run)
