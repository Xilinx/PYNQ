# Verify file write/read round-trip over gRPC (host -> target -> host).

import os

from pynq.remote.selftest.control import CONTINUE


def run(ctx, res):
    if ctx.dev is None:
        return CONTINUE

    try:
        payload = b"pynq-remote-hosttest " + os.urandom(16)
        path = "/tmp/pynq_remote_hosttest.bin"
        ctx.dev.write_file(path, payload)
        back = ctx.dev.read_file(path)
        if back == payload:
            res.ok(f"{len(payload)}-byte file survived the round-trip")
        else:
            res.bad(f"file mismatch (wrote {len(payload)}B, read {len(back)}B)")
    except Exception as e:
        res.bad(f"file round-trip failed -- {e!r}")

    return CONTINUE
