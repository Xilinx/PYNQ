#!/usr/bin/env python3
"""PYNQ.remote host-side self-test.

    pynq-remote-selftest --ip <target-ip> [--port 7967] [--bitstream base.xsa]
    python3 -m pynq.remote.selftest --ip <target-ip> [--port 7967] [--bitstream base.xsa]
"""
import argparse
import os
import socket
import sys


RF_BOARDS = {"zcu208", "zcu111", "rfsoc4x2"}


def main():
    ap = argparse.ArgumentParser(description="PYNQ.remote host-side self-test")
    ap.add_argument("--ip", required=True, help="target board IP address")
    ap.add_argument("--port", type=int, default=7967, help="gRPC port (default 7967)")
    ap.add_argument("--bitstream", default=None,
                    help="base overlay (.xsa/.bit) for the overlay/MMIO + RF stages")
    args = ap.parse_args()

    n = {"pass": 0, "fail": 0, "skip": 0}
    def ok(m):   n["pass"] += 1; print(f"  [PASS] {m}")
    def bad(m):  n["fail"] += 1; print(f"  [FAIL] {m}")
    def skip(m): n["skip"] += 1; print(f"  [SKIP] {m}")

    print("======================================================")
    print(f" PYNQ.remote host test -> {args.ip}:{args.port}")
    print("======================================================")

    # ---- host environment preflight -------------------------------------
    print("[1] Host environment (venv / pynq / numpy / grpc)")
    try:
        import numpy as np  # noqa: F401
        ok(f"numpy importable ({np.__version__})")
    except Exception as e:
        bad(f"numpy not importable -- {e!r}")
        np = None
    try:
        import grpc  # noqa: F401
        ok("grpc importable")
    except Exception as e:
        bad(f"grpc not importable -- {e!r}")
    try:
        import pynq  # noqa: F401
        from pynq import Device
        from pynq.pl_server.remote_device import RemoteDevice
        ok(f"pynq importable ({getattr(pynq, '__version__', '?')})")
    except Exception as e:
        bad("pynq not importable -- install it on the host first, e.g. "
            f"`pip install \"pynq @ git+https://github.com/Xilinx/PYNQ.git\"` (details: {e!r})")
        return _summary(n)
    if np is None:
        return _summary(n)

    # ---- connectivity: TCP reach, then gRPC channel handshake -----------
    print("[2] Connectivity (TCP reach + gRPC channel-ready)")
    try:
        with socket.create_connection((args.ip, args.port), timeout=5):
            ok(f"TCP {args.ip}:{args.port} reachable")
    except Exception as e:
        bad(f"cannot reach {args.ip}:{args.port} -- board booted? pynq-remote up? ({e!r})")
        return _summary(n)
    try:
        ch = grpc.insecure_channel(f"{args.ip}:{args.port}")
        grpc.channel_ready_future(ch).result(timeout=5)
        ch.close()
        ok("gRPC channel ready")
    except Exception as e:
        bad(f"gRPC handshake failed -- {e!r}")
        return _summary(n)

    # ---- connect + identity (target -> host) ----------------------------
    print("[3] Connect + identity")
    try:
        dev = RemoteDevice(0, args.ip, args.port)
        # Route pynq's default Register/MMIO calls (e.g. overlay download) here.
        Device.active_device = dev
        kind = (dev.name or "").strip().lower()
        ok(f"connected; arch={dev.arch}, board={dev.name} (profile: {kind})")
    except Exception as e:
        bad(f"could not open RemoteDevice on {args.ip}:{args.port} -- {e!r}")
        return _summary(n)

    # ---- board supporting packages (host side, keyed on board) ----------
    print("[4] Host support packages for this board")
    if kind in RF_BOARDS:
        for mod in ("xrfdc", "xrfclk"):
            try:
                __import__(mod)
                ok(f"{mod} importable on host")
            except Exception as e:
                bad(f"{mod} not importable (RF board needs it host-side) -- {e!r}")
    else:
        ok("no board-specific host packages required")

    # ---- file round-trip (host -> target -> host) -----------------------
    print("[5] File round-trip (write host->target, read target->host)")
    try:
        payload = b"pynq-remote-hosttest " + os.urandom(16)
        path = "/tmp/pynq_remote_hosttest.bin"
        dev.write_file(path, payload)
        back = dev.read_file(path)
        if back == payload:
            ok(f"{len(payload)}-byte file survived the round-trip")
        else:
            bad(f"file mismatch (wrote {len(payload)}B, read {len(back)}B)")
    except Exception as e:
        bad(f"file round-trip failed -- {e!r}")

    # ---- buffer/DMA round-trip (host -> target -> host) -----------------
    print("[6] Buffer round-trip (allocate, sync_to_device, sync_from_device)")
    try:
        buf = dev.allocate((1024,), "u4")
        ref = np.arange(1024, dtype="u4")
        buf[:] = ref
        buf.sync_to_device()          # host -> target
        buf[:] = 0                    # clobber the local copy
        buf.sync_from_device()        # target -> host
        pa = int(buf.physical_address)
        if np.array_equal(buf, ref) and pa != 0:
            ok(f"1024xu4 buffer intact after host->target->host; phys_addr=0x{pa:x}")
        elif pa == 0:
            bad("buffer round-trip ok but physical_address is 0")
        else:
            bad("buffer data mismatch after sync round-trip")
        try:
            buf.freebuffer()
        except Exception:
            pass
    except Exception as e:
        bad(f"buffer round-trip failed -- {e!r}")

    # ---- overlay download + MMIO (requires --bitstream) -----------------
    ol = None
    if args.bitstream:
        print("[7] Overlay download (host->target) + PL program")
        try:
            from pynq import Overlay
            ol = Overlay(args.bitstream, device=dev)
            ok(f"downloaded {os.path.basename(args.bitstream)} and programmed the PL")
        except Exception as e:
            bad(f"overlay download failed -- {e!r}")

        if ol is not None:
            print("[8] MMIO round-trip on an AXI GPIO (host->target write, target->host read)")
            try:
                from pynq import MMIO
                gpios = {k: v for k, v in ol.ip_dict.items()
                         if "gpio" in str(v.get("type", "")).lower()}
                name = next((k for k in gpios if "led" in k.lower()), None)
                if name is None and gpios:
                    name = next(iter(gpios))
                if name is None:
                    skip("no AXI GPIO in the overlay to MMIO-test")
                else:
                    addr = int(gpios[name]["phys_addr"])
                    m = MMIO(addr, 0x10, device=dev)
                    if "led" in name.lower():
                        test = 0x5
                        m.write(0x0, test)                 # host -> target
                        rb = m.read(0x0) & 0xF             # target -> host
                        if rb == test:
                            ok(f"{name}@0x{addr:x}: wrote 0x{test:x}, read 0x{rb:x}")
                        else:
                            bad(f"{name}: wrote 0x{test:x} but read 0x{rb:x}")
                        m.write(0x0, 0x0)
                    else:
                        val = m.read(0x0)                  # target -> host (read-only IP)
                        ok(f"{name}@0x{addr:x}: MMIO read returned 0x{val:x} (read-only check)")
            except Exception as e:
                bad(f"MMIO test failed -- {e!r}")
    else:
        skip("[7] Overlay/MMIO skipped (pass --bitstream <base.xsa> to enable)")

    # ---- board-specific checks (keyed on dev.name) ----------------------
    print(f"[9] Board-specific checks ({kind})")
    if kind in RF_BOARDS:
        _rf_light(ok, bad, skip, dev, ol)
    elif kind == "zcu104":
        _zcu104_specific(ok, bad, skip, dev, ol)
    else:
        skip(f"{kind}: no board-specific host checks defined")

    return _summary(n)


def _rf_light(ok, bad, skip, dev, ol):
    if ol is None:
        skip("RF check needs an RF overlay -- rerun with --bitstream <rf_base.xsa>")
        return
    try:
        from pynq import MMIO
    except Exception as e:
        bad(f"cannot import MMIO for RF check -- {e!r}")
        return
    rfdc = {k: v for k, v in ol.ip_dict.items()
            if "rf_data_converter" in str(v.get("type", "")).lower()
            or "usp_rf" in str(v.get("type", "")).lower()}
    if not rfdc:
        bad("no RF Data Converter IP found in the overlay ip_dict")
        return
    name = next(iter(rfdc))
    try:
        addr = int(rfdc[name]["phys_addr"])
        m = MMIO(addr, 0x40, device=dev)
        ver = m.read(0x0)                                 # IP version register (target->host)
        ok(f"RFdc {name}@0x{addr:x} reachable over gRPC (version reg=0x{ver:x})")
    except Exception as e:
        bad(f"RFdc MMIO read failed over gRPC -- {e!r}")
    drv = getattr(ol, name, None)
    if drv is not None and type(drv).__name__ == "RFdc":
        na = len(getattr(drv, "adc_tiles", []) or [])
        nd = len(getattr(drv, "dac_tiles", []) or [])
        ok(f"xrfdc driver bound: {na} ADC tile(s), {nd} DAC tile(s)")
    else:
        skip("xrfdc driver did not bind to the RFdc IP (driver present but not RFdc)")


def _zcu104_specific(ok, bad, skip, dev, ol):
    if ol is None:
        skip("ZCU104 GPIO check needs the base overlay -- rerun with --bitstream")
        return
    try:
        from pynq import MMIO
    except Exception as e:
        bad(f"cannot import MMIO for GPIO check -- {e!r}")
        return
    gpios = {k: v for k, v in ol.ip_dict.items()
             if "gpio" in str(v.get("type", "")).lower()}
    targets = {k: v for k, v in gpios.items()
               if any(t in k.lower() for t in ("led", "btn", "sw", "switch", "button"))}
    if not targets:
        skip("no LED/button/switch AXI GPIO found in the ZCU104 overlay")
        return
    for name, info in targets.items():
        try:
            addr = int(info["phys_addr"])
            m = MMIO(addr, 0x10, device=dev)
            val = m.read(0x0)
            ok(f"{name}@0x{addr:x}: GPIO data reg readable over gRPC (0x{val:x})")
        except Exception as e:
            bad(f"{name}: GPIO MMIO read failed -- {e!r}")


def _summary(n):
    print("------------------------------------------------------")
    print(f" summary: {n['pass']} passed, {n['fail']} failed, {n['skip']} skipped")
    print("======================================================")
    return 1 if n["fail"] else 0


if __name__ == "__main__":
    sys.exit(main())
