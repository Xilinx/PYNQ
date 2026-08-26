"""Pass/fail reporting helpers for on-board Python selftest modules."""

import json
import os
import subprocess
import sys

_passed = 0
_failed = 0
_skipped = 0


class SkipError(Exception):
    """Optional skip (orchestrator may count separately). Rare for manifest tests."""


class FailError(Exception):
    pass


def ok(msg):
    global _passed
    _passed += 1
    print("  [PASS] %s" % msg)


def bad(msg):
    global _failed
    _failed += 1
    print("  [FAIL] %s" % msg)


def skip(msg):
    global _skipped
    _skipped += 1
    print("  [SKIP] %s" % msg)


def counts():
    return _passed, _failed, _skipped


def reset_counts():
    global _passed, _failed, _skipped
    _passed = _failed = _skipped = 0


def params():
    raw = os.environ.get("SELFTEST_PARAMS", "{}")
    try:
        return json.loads(raw)
    except json.JSONDecodeError as error:
        raise FailError("SELFTEST_PARAMS is not valid JSON: %r (%s)" % (raw, error))


def sh(cmd, timeout=15):
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
    return p.returncode, p.stdout.strip()


def read(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def read_priv(path):
    txt = read(path)
    if txt:
        return txt
    rc, out = sh("cat %s 2>/dev/null" % path, timeout=10)
    return out if rc == 0 else ""


def main_entry(run_fn):
    try:
        run_fn(params())
    except SkipError as e:
        skip(str(e))
    except FailError as e:
        bad(str(e))
    except Exception as e:
        bad("errored: %r" % e)
    _, failed, skipped = counts()
    if failed:
        sys.exit(1)
    if skipped:
        sys.exit(2)
    sys.exit(0)
