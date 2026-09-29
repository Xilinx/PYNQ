# MMIO read/write on an AXI GPIO in the downloaded overlay (requires --bitstream).

from pynq.remote.selftest.control import CONTINUE


def run(ctx, res):
    if not ctx.bitstream:
        return CONTINUE

    if ctx.overlay is None:
        res.bad("overlay not loaded (--bitstream provided but download/program failed)")
        return CONTINUE

    if ctx.dev is None:
        return CONTINUE

    try:
        from pynq import MMIO

        ol = ctx.overlay
        gpios = {
            k: v
            for k, v in ol.ip_dict.items()
            if "gpio" in str(v.get("type", "")).lower()
        }
        name = next((k for k in gpios if "led" in k.lower()), None)
        if name is None and gpios:
            name = next(iter(gpios))
        if name is None:
            res.bad("no AXI GPIO in the overlay to MMIO-test")
            return CONTINUE

        addr = int(gpios[name]["phys_addr"])
        m = MMIO(addr, 0x10, device=ctx.dev)
        if "led" in name.lower():
            test = 0x5
            m.write(0x0, test)
            rb = m.read(0x0) & 0xF
            if rb == test:
                res.ok(f"{name}@0x{addr:x}: wrote 0x{test:x}, read 0x{rb:x}")
            else:
                res.bad(f"{name}: wrote 0x{test:x} but read 0x{rb:x}")
            m.write(0x0, 0x0)
        else:
            val = m.read(0x0)
            res.ok(f"{name}@0x{addr:x}: MMIO read returned 0x{val:x} (read-only check)")
    except Exception as e:
        res.bad(f"MMIO test failed -- {e!r}")

    return CONTINUE
