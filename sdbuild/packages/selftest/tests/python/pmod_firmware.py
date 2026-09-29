# Verify Pmod/Grove MicroBlaze firmware files are installed.

# p: manifest params dict for this test (from selftest.json "params").
import os

import pynq.lib.pmod as m

from results import bad, ok, sh, main_entry


def run(p=None):
    pdir = os.path.dirname(m.__file__)
    _, n = sh("ls %s/pmod_*.bin 2>/dev/null | wc -l" % pdir)
    nbin = int(n) if n.isdigit() else 0
    if nbin >= 20:
        ok("pmod firmware present (%d .bin in %s)" % (nbin, pdir))
    else:
        bad("expected >=20 pmod .bin, found %d" % nbin)
    if os.path.isfile("%s/pmod_oled.bin" % pdir):
        ok("pmod_oled.bin present")
    else:
        bad("pmod_oled.bin missing")
    _, ng = sh("ls %s/pmod_grove_*.bin 2>/dev/null | wc -l" % pdir)
    if ng.isdigit() and int(ng) >= 1:
        ok("pmod_grove_*.bin present (%s)" % ng)
    else:
        bad("pmod_grove_*.bin missing")


if __name__ == "__main__":
    main_entry(run)
