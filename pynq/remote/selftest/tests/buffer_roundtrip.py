# Verify DMA buffer allocate/sync round-trip over gRPC.

from pynq.remote.selftest.control import CONTINUE


def run(ctx, res):
    if ctx.dev is None or ctx.np is None:
        return CONTINUE

    np = ctx.np
    try:
        buf = ctx.dev.allocate((1024,), "u4")
        ref = np.arange(1024, dtype="u4")
        buf[:] = ref
        buf.sync_to_device()
        buf[:] = 0
        buf.sync_from_device()
        pa = int(buf.physical_address)
        if np.array_equal(buf, ref) and pa != 0:
            res.ok(
                f"1024xu4 buffer intact after host->target->host; phys_addr=0x{pa:x}"
            )
        elif pa == 0:
            res.bad("buffer round-trip ok but physical_address is 0")
        else:
            res.bad("buffer data mismatch after sync round-trip")
        try:
            buf.freebuffer()
        except Exception:
            pass
    except Exception as e:
        res.bad(f"buffer round-trip failed -- {e!r}")

    return CONTINUE
