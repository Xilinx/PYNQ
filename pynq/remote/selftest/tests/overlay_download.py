# Download and program base overlay on target when --bitstream is given.

import os

from pynq.remote.selftest.control import CONTINUE


def run(ctx, res):
    if not ctx.bitstream:
        res.skip("overlay download skipped (pass --bitstream <base.xsa> to enable)")
        return CONTINUE

    if ctx.dev is None:
        return CONTINUE

    try:
        from pynq import Overlay

        ctx.overlay = Overlay(ctx.bitstream, device=ctx.dev)
        res.ok(f"downloaded {os.path.basename(ctx.bitstream)} and programmed the PL")
    except Exception as e:
        res.bad(f"overlay download failed -- {e!r}")
        ctx.overlay = None

    return CONTINUE
