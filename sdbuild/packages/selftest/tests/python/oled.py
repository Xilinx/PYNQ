# Verify on-board OLED display initialises and accepts text.
# Params: module, class, line1, line2 (all required except line2).

from board_helpers import overlay
from results import FailError, ok, main_entry


def run(p=None):
    p = p or {}
    overlay(p.get("bitstream"))
    mod_name = p.get("module")
    cls_name = p.get("class")
    if not mod_name or not cls_name:
        raise FailError("manifest params.module and params.class required")
    try:
        mod = __import__(mod_name, fromlist=[cls_name])
        cls = getattr(mod, cls_name)
    except (ImportError, AttributeError) as e:
        raise FailError("%s.%s not available: %r" % (mod_name, cls_name, e))
    d = cls()
    line1 = p.get("line1", "PYNQ self-test")
    line2 = p.get("line2", "")
    text = line1 if not line2 else "%s\n%s" % (line1, line2)
    d.write(text)
    ok("on-board OLED initialised + wrote text (verify by eye)")


if __name__ == "__main__":
    main_entry(run)
