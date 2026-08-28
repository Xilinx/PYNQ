# Verify LEDs, buttons, and switches on the base overlay respond.
# Params: bitstream.

from board_helpers import overlay
from results import bad, ok, params, main_entry


def run(p=None):
    base = overlay((p or {}).get("bitstream"))
    nsw, nbtn, nled = len(base.switches), len(base.buttons), len(base.leds)
    sw = [base.switches[i].read() for i in range(nsw)]
    bt = [base.buttons[i].read() for i in range(nbtn)]
    for i in range(nled):
        base.leds[i].on()
    for i in range(nled):
        base.leds[i].off()
    if all(v in (0, 1) for v in sw + bt):
        ok(
            "GPIO ok (%d switches=%s, %d buttons=%s, %d LEDs toggled)"
            % (nsw, sw, nbtn, bt, nled)
        )
    else:
        bad("GPIO returned non-binary values (sw=%s bt=%s)" % (sw, bt))


if __name__ == "__main__":
    main_entry(run)
