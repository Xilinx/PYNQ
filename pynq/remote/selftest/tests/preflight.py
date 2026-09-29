# Verify host Python environment: numpy, grpc, and pynq importable.

from pynq.remote.selftest.control import CONTINUE, STOP


def run(ctx, res):
    try:
        import numpy as np

        ctx.np = np
        res.ok(f"numpy importable ({np.__version__})")
    except Exception as e:
        res.bad(f"numpy not importable -- {e!r}")
        ctx.np = None

    try:
        import grpc  # noqa: F401

        ctx.imports["grpc"] = grpc
        res.ok("grpc importable")
    except Exception as e:
        res.bad(f"grpc not importable -- {e!r}")

    try:
        import pynq
        from pynq import Device
        from pynq.pl_server.remote_device import RemoteDevice

        ctx.imports["pynq"] = pynq
        ctx.imports["Device"] = Device
        ctx.imports["RemoteDevice"] = RemoteDevice
        res.ok(f"pynq importable ({getattr(pynq, '__version__', '?')})")
    except Exception as e:
        res.bad(
            "pynq not importable -- install it on the host first, e.g. "
            f'`pip install "pynq @ git+https://github.com/Xilinx/PYNQ.git"` '
            f"(details: {e!r})"
        )
        return STOP

    if ctx.np is None:
        return STOP
    return CONTINUE
