# Verify RGB LEDs on the overlay accept write cycles.

# p: manifest params dict for this test (from selftest.json "params").
from board_helpers import overlay
from results import bad, ok, main_entry


def run(p=None):
    base = overlay()
    n = len(base.rgbleds)
    for i in range(n):
        base.rgbleds[i].write(0x7)
    for i in range(n):
        base.rgbleds[i].write(0x0)
    if n >= 1:
        ok("%d RGB LEDs cycled (verify by eye)" % n)
    else:
        bad("no RGB LEDs found on the overlay")


if __name__ == "__main__":
    main_entry(run)
