# Verify all overlay LEDs can be driven on, off, and toggled.
# Params: bitstream, expected_count.

from board_helpers import overlay
from results import FailError, bad, ok, main_entry


def run(p=None):
    p = p or {}
    bit = p.get("bitstream")
    base = overlay(bit)
    if not hasattr(base, "leds"):
        raise FailError("overlay has no leds")
    n = len(base.leds)
    expected = p.get("expected_count")
    for i in range(n):
        base.leds[i].on()
    for i in range(n):
        base.leds[i].off()
    for i in range(n):
        base.leds[i].toggle()
    for i in range(n):
        base.leds[i].toggle()
    if expected is not None and n != expected:
        bad("expected %d LEDs, base.leds has %d" % (expected, n))
    elif n >= 1:
        ok("%d LEDs driven (on/off/toggle)" % n)
    else:
        bad("no LEDs found on the overlay")


if __name__ == "__main__":
    main_entry(run)
