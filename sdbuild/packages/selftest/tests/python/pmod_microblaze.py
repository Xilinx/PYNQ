# Verify PMOD MicroBlaze IOP compiles and runs on the overlay.
# Params: bitstream, port.

from board_helpers import free_iop, overlay
from results import bad, ok, params, main_entry


def run(p=None):
    p = p or {}
    port = p.get("port", "PMODA")
    base = overlay(p.get("bitstream"))
    from pynq.lib import MicroblazeLibrary

    iop = getattr(base, port)
    free_iop(iop)
    lib = MicroblazeLibrary(iop, ["gpio"])
    ran = hasattr(lib, "gpio_open")
    del lib
    if ran:
        ok("%s MicroBlaze IOP compiled + ran a program (gpio library)" % port)
    else:
        bad("MicroblazeLibrary loaded but the gpio API is missing")


if __name__ == "__main__":
    main_entry(run)
