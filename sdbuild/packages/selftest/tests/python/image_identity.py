# Verify image reports PynqLinux identity and a readable version string.

# p: manifest params dict for this test (from selftest.json "params").
import re

from results import bad, ok, read, main_entry


def run(p=None):
    vals = {}
    for line in read("/etc/os-release").splitlines():
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            vals[k] = v.strip().strip('"')
    name = vals.get("NAME", "")
    ver = vals.get("VERSION_ID", "")
    codename = vals.get("VERSION_CODENAME", "")
    if not codename:
        m = re.search(r"\(([^)]+)\)", vals.get("VERSION", ""))
        codename = m.group(1) if m else ""
    if name == "PynqLinux":
        ok("os-release NAME=PynqLinux")
    else:
        bad("os-release NAME is %r, not PynqLinux" % name)
    if ver:
        ok("os-release VERSION_ID=%s (codename %s)" % (ver, codename or "?"))
    else:
        bad("os-release VERSION_ID is empty")
    rev = read("/home/xilinx/REVISION")
    if ver and ("Release %s" % ver) in rev:
        ok("REVISION matches os-release (Release %s)" % ver)
    else:
        bad("REVISION does not match os-release version %r (REVISION: %r)" % (ver, rev.strip()))
    if codename:
        if codename in rev:
            ok("codename %s consistent across os-release + REVISION" % codename)
        else:
            bad("codename %s in os-release but not in REVISION" % codename)


if __name__ == "__main__":
    main_entry(run)
