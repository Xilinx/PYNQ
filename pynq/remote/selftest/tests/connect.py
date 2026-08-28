# Open RemoteDevice and record board identity for later tests.

from pynq.remote.selftest.control import CONTINUE, STOP


def run(ctx, res):
    RemoteDevice = ctx.imports.get("RemoteDevice")
    Device = ctx.imports.get("Device")
    if RemoteDevice is None or Device is None:
        return STOP

    try:
        ctx.dev = RemoteDevice(0, ctx.ip, ctx.port)
        Device.active_device = ctx.dev
        ctx.board_kind = (ctx.dev.name or "").strip().lower()
        res.ok(
            f"connected; arch={ctx.dev.arch}, board={ctx.dev.name} "
            f"(profile: {ctx.board_kind})"
        )
    except Exception as e:
        res.bad(f"could not open RemoteDevice on {ctx.ip}:{ctx.port} -- {e!r}")
        return STOP

    return CONTINUE
