# Verify PS SPI controllers and reference clock devices are present.

# p: manifest params dict for this test (from selftest.json "params").
import os

from results import FailError, bad, ok, read_priv, sh, main_entry

SPI_DEVS = ("/dev/spidev0.0", "/dev/spidev0.1", "/dev/spidev0.2", "/dev/spidev1.0")
SPI_REF_MIN_HZ = 10000000


def run(p=None):
    missing = [d for d in SPI_DEVS if not os.path.exists(d)]
    if not missing:
        ok("spidev nodes present (%s)" % ", ".join(os.path.basename(d) for d in SPI_DEVS))
    else:
        bad("missing spidev nodes: %s" % ", ".join(missing))
    summary = read_priv("/sys/kernel/debug/clk/clk_summary")
    if not summary:
        raise FailError("clk_summary not readable (need root) -- cannot verify SPI ref clocks")
    for ref in ("spi0_ref", "spi1_ref"):
        rate = 0
        for line in summary.splitlines():
            toks = line.split()
            if ref in toks:
                try:
                    rate = int(toks[toks.index(ref) + 4])
                except (IndexError, ValueError):
                    rate = 0
                break
        if rate == 0:
            bad("%s not found/parseable in clk_summary" % ref)
        elif rate >= SPI_REF_MIN_HZ:
            ok("%s = %d Hz (healthy; not the 1 MHz misconfig)" % (ref, rate))
        else:
            bad(
                "%s = %d Hz (<%d Hz; 1 MHz-class misconfig breaks SPI transfers)"
                % (ref, rate, SPI_REF_MIN_HZ)
            )
    rc, _ = sh("dmesg 2>/dev/null | grep -qi 'spi.*transfer timed out'")
    if rc != 0:
        ok("no 'SPI transfer timed out' in dmesg")
    else:
        bad("dmesg shows 'SPI transfer timed out' (SPI controller failing)")


if __name__ == "__main__":
    main_entry(run)
