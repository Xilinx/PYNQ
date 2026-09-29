# RFdc MMIO over gRPC and xrfdc driver binding when overlay contains RFdc IP.

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
    except Exception as e:
        res.bad(f"cannot import MMIO for RFdc check -- {e!r}")
        return CONTINUE

    ol = ctx.overlay
    rfdc = {
        k: v
        for k, v in ol.ip_dict.items()
        if "rf_data_converter" in str(v.get("type", "")).lower()
        or "usp_rf" in str(v.get("type", "")).lower()
    }
    if not rfdc:
        if ctx.rf_board:
            res.bad("no RF Data Converter IP found in the overlay ip_dict")
        return CONTINUE

    name = next(iter(rfdc))
    try:
        addr = int(rfdc[name]["phys_addr"])
        m = MMIO(addr, 0x40, device=ctx.dev)
        ver = m.read(0x0)
        res.ok(f"RFdc {name}@0x{addr:x} reachable over gRPC (version reg=0x{ver:x})")
    except Exception as e:
        res.bad(f"RFdc MMIO read failed over gRPC -- {e!r}")

    drv = getattr(ol, name, None)
    if drv is not None and type(drv).__name__ == "RFdc":
        na = len(getattr(drv, "adc_tiles", []) or [])
        nd = len(getattr(drv, "dac_tiles", []) or [])
        res.ok(f"xrfdc driver bound: {na} ADC tile(s), {nd} DAC tile(s)")
    else:
        res.bad("xrfdc driver did not bind to the RFdc IP")

    return CONTINUE
