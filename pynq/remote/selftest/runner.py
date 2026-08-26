"""Run host-side PYNQ.remote selftest modules in order."""

import argparse
import importlib
import sys

from pynq.remote.selftest.control import STOP
from pynq.remote.selftest.context import Context
from pynq.remote.selftest.results import Results
from pynq.remote.selftest import steps


def _run_step(label, module, ctx, res):
    if label:
        print(label)
    stop = module.run(ctx, res)
    return stop is STOP


def main(argv=None):
    ap = argparse.ArgumentParser(description="PYNQ.remote host-side self-test")
    ap.add_argument("--ip", required=True, help="target board IP address")
    ap.add_argument("--port", type=int, default=7967, help="gRPC port (default 7967)")
    ap.add_argument(
        "--bitstream",
        default=None,
        help="base overlay (.xsa/.bit) for the overlay/MMIO + RF stages",
    )
    ap.add_argument(
        "--test",
        dest="single",
        metavar="MODULE",
        help="run one test module by name (e.g. connect, buffer_roundtrip)",
    )
    ap.add_argument("--list", action="store_true", help="list test module names")
    args = ap.parse_args(argv)

    if args.list:
        for _, mod in steps.STEPS:
            print(mod.__name__.rsplit(".", 1)[-1])
        return 0

    ctx = Context(ip=args.ip, port=args.port, bitstream=args.bitstream)
    res = Results()

    print("======================================================")
    print(f" PYNQ.remote host test -> {ctx.ip}:{ctx.port}")
    print("======================================================")

    if args.single:
        return _run_single(args.single, ctx, res)

    for label, module in steps.STEPS:
        if _run_step(label, module, ctx, res):
            return res.summary()

    return res.summary()


def _run_single(name, ctx, res):
    path = f"pynq.remote.selftest.tests.{name}"
    try:
        module = importlib.import_module(path)
    except ImportError:
        print(f"error: unknown test module {name!r}", file=sys.stderr)
        return 2
    if _run_step(f"[test] {name}", module, ctx, res):
        return res.summary()
    return res.summary()


if __name__ == "__main__":
    sys.exit(main())
