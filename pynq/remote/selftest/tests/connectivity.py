# Verify TCP reachability and gRPC channel handshake to the appliance.

import socket

from pynq.remote.selftest.control import CONTINUE, STOP


def run(ctx, res):
    grpc = ctx.imports.get("grpc")
    if grpc is None:
        return STOP

    try:
        with socket.create_connection((ctx.ip, ctx.port), timeout=5):
            res.ok(f"TCP {ctx.ip}:{ctx.port} reachable")
    except Exception as e:
        res.bad(
            f"cannot reach {ctx.ip}:{ctx.port} -- board booted? pynq-remote up? ({e!r})"
        )
        return STOP

    try:
        ch = grpc.insecure_channel(f"{ctx.ip}:{ctx.port}")
        grpc.channel_ready_future(ch).result(timeout=5)
        ch.close()
        res.ok("gRPC channel ready")
    except Exception as e:
        res.bad(f"gRPC handshake failed -- {e!r}")
        return STOP

    return CONTINUE
