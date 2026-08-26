# Verify RF reference clocks (init_rf_clks or SPI clock enumeration).
# Params: mode (init_rf_clks|spi_enumeration), load_qpsk, message, min_spi_devices.

import os

from board_helpers import init_rf_clks, overlay
from results import bad, ok, main_entry


def run(p=None):
    p = p or {}
    mode = p.get("mode", "init_rf_clks")
    if mode == "init_rf_clks":
        base = overlay(p.get("bitstream"))
        init_rf_clks(base)
        ok(p.get("message", "init_rf_clks() configured RF reference clocks"))
        return

    if mode == "spi_enumeration":
        if p.get("load_qpsk"):
            from rfsoc_qpsk.qpsk_overlay import QpskOverlay

            QpskOverlay()
        min_devs = int(p.get("min_spi_devices", 4))
        spidir = "/sys/bus/spi/devices"
        devs = sorted(os.listdir(spidir)) if os.path.isdir(spidir) else []
        if len(devs) >= min_devs:
            ok("RF clock chips enumerated on SPI (%d devices: %s)" % (len(devs), " ".join(devs)))
        else:
            bad(
                "expected >=%d SPI clock devices, found %d (%s)"
                % (min_devs, len(devs), " ".join(devs) or "none")
            )
        return

    bad("unknown rf_clocks mode: %r" % mode)


if __name__ == "__main__":
    main_entry(run)
