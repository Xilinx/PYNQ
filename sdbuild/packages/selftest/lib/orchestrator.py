#!/usr/bin/env python3
"""Run the board selftest manifest."""

import argparse
import json
import os
import subprocess
import sys
import time

ROOT = os.environ.get("SELFTEST_ROOT", "/usr/local/share/pynq-selftest")
MANIFEST_DIR = os.path.join(ROOT, "manifests")
LOG_FILE = os.environ.get(
    "PYNQ_TEST_LOG",
    "/tmp/pynq-selftest.%s.log" % time.strftime("%Y%m%d-%H%M%S"),
)


def board_name():
    board = os.environ.get("BOARD", "")
    if board:
        return board
    path = "/proc/device-tree/chosen/pynq_board"
    if os.path.exists(path):
        with open(path, "rb") as f:
            return f.read().split(b"\0")[0].decode()
    return "Unknown"


def load_manifest(board):
    path = os.path.join(MANIFEST_DIR, "%s.json" % board)
    if not os.path.isfile(path):
        print("error: no manifest at %s" % path, file=sys.stderr)
        sys.exit(2)
    with open(path) as f:
        return json.load(f)


def test_label(entry):
    return entry.get("name") or entry["id"]


def run_test(entry, num, run_hw, log):
    test_id = entry["id"]
    timeout = entry.get("timeout", 30)
    hardware = entry.get("hardware", False)
    params = json.dumps(entry.get("params") or {})
    label = test_label(entry)
    print("[%d] %s" % (num, label))
    sys.stdout.flush()
    cmd = [
        "bash",
        os.path.join(ROOT, "lib/run_test.sh"),
        test_id,
        str(timeout),
        params,
        "true" if hardware else "false",
        "true" if run_hw else "false",
    ]
    log.debug("run %s", " ".join(cmd))
    result = subprocess.run(cmd)
    return result.returncode


def parse_args():
    ap = argparse.ArgumentParser(description="PYNQ image self-test")
    ap.add_argument("--no-peripherals", action="store_true",
                    help="software-only; skip hardware checks")
    ap.add_argument("--test", dest="single", metavar="ID",
                    help="run one test by manifest id")
    ap.add_argument("--list", action="store_true", help="list manifest test ids")
    return ap.parse_args()


def main():
    import logging

    log = logging.getLogger("pynq-selftest")
    log.setLevel(logging.DEBUG)
    try:
        fh = logging.FileHandler(LOG_FILE)
        fh.setFormatter(logging.Formatter("%(asctime)s %(levelname)-5s %(message)s", "%H:%M:%S"))
        log.addHandler(fh)
    except OSError:
        pass

    args = parse_args()
    board = board_name()
    manifest = load_manifest(board)
    tests = manifest.get("tests") or []
    defaults = manifest.get("defaults") or {}
    run_hw = not args.no_peripherals

    if args.list:
        for entry in tests:
            print(entry["id"])
        return 0

    if args.single:
        tests = [t for t in tests if t["id"] == args.single]
        if not tests:
            print("error: test id %r not in manifest" % args.single, file=sys.stderr)
            return 2

    bar = "=" * 54
    print(bar)
    print(" PYNQ image self-test  (%s)" % board)
    print(" host: %s   kernel: %s" % (os.uname().nodename, os.uname().release))
    print(
        " mode: %s"
        % ("full (peripheral tests enabled)" if run_hw else "--no-peripherals (software-only)")
    )
    print(" log: %s" % LOG_FILE)
    print(bar)

    passed = failed = skipped = 0
    for num, entry in enumerate(tests, 1):
        if entry.get("hardware", defaults.get("hardware", False)) and not run_hw:
            print("[%d] %s" % (num, test_label(entry)))
            print("  [SKIP] hardware check skipped (--no-peripherals)")
            skipped += 1
            continue
        rc = run_test(entry, num, run_hw, log)
        if rc == 0:
            passed += 1
        elif rc == 2:
            skipped += 1
        else:
            failed += 1

    print("-" * 54)
    print(" summary: %d passed, %d failed, %d skipped" % (passed, failed, skipped))
    print(bar)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
