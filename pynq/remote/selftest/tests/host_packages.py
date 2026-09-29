# Verify board-specific Python packages are importable on the host.

from pynq.remote.selftest.control import CONTINUE


def run(ctx, res):
    if ctx.rf_board:
        for mod in ("xrfdc", "xrfclk"):
            try:
                __import__(mod)
                res.ok(f"{mod} importable on host")
            except Exception as e:
                res.bad(f"{mod} not importable (RF board needs it host-side) -- {e!r}")
    else:
        res.ok("no board-specific host packages required")
    return CONTINUE
