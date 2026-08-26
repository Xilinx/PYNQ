# Verify buttons and DIP switches return binary values.
# Params: bitstream, expected_buttons, expected_switches.

from board_helpers import overlay
from results import FailError, bad, ok, main_entry


def run(p=None):
    p = p or {}
    bit = p.get("bitstream")
    base = overlay(bit)
    if not hasattr(base, "buttons") or not hasattr(base, "switches"):
        raise FailError("overlay has no buttons/switches")
    nbtn, nsw = len(base.buttons), len(base.switches)
    bt = [base.buttons[i].read() for i in range(nbtn)]
    sw = [base.switches[i].read() for i in range(nsw)]
    exp_btn = p.get("expected_buttons")
    exp_sw = p.get("expected_switches")
    if exp_btn is not None and nbtn != exp_btn:
        bad("expected %d buttons, found %d" % (exp_btn, nbtn))
    elif exp_sw is not None and nsw != exp_sw:
        bad("expected %d switches, found %d" % (exp_sw, nsw))
    elif all(v in (0, 1) for v in bt + sw):
        ok("buttons=%s switches=%s (all binary, %d+%d channels)" % (bt, sw, nbtn, nsw))
    else:
        bad("button/switch read invalid (nbtn=%d nsw=%d bt=%s sw=%s)" % (nbtn, nsw, bt, sw))


if __name__ == "__main__":
    main_entry(run)
