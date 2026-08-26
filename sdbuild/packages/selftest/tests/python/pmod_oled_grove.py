# Verify Pmod OLED display and Grove temperature sensor.
# Params: bitstream, oled_port, grove_port, grove_pin, oled_text.

from board_helpers import free_iop, overlay
from results import bad, ok, params, main_entry


def run(p=None):
    p = p or {}
    oled_port = p.get("oled_port", "PMODA")
    grove_port = p.get("grove_port", "PMODB")
    grove_pin = p.get("grove_pin", "G4")
    base = overlay(p.get("bitstream"))
    from pynq.lib import pmod
    from pynq.lib.pmod import Grove_TMP, Pmod_OLED

    grove_const = getattr(pmod, "PMOD_GROVE_%s" % grove_pin)

    iop_oled = getattr(base, oled_port)
    free_iop(iop_oled)
    oled = Pmod_OLED(iop_oled)
    oled.clear()
    oled.write(p.get("oled_text", "PYNQ self-test"))
    ok("Pmod OLED on %s loaded + wrote (verify display by eye)" % oled_port)

    iop_grove = getattr(base, grove_port)
    free_iop(iop_grove)
    tmp = Grove_TMP(iop_grove, grove_const)
    t = tmp.read()
    if 0 < t < 60:
        ok("Grove temperature %.2f C on %s %s (in range)" % (t, grove_port, grove_pin))
    else:
        bad("Grove temperature %.2f C out of the expected 0-60 C range" % t)


if __name__ == "__main__":
    main_entry(run)
