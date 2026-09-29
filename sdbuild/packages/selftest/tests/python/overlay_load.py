# Verify base overlay loads and exposes a non-empty ip_dict.
# Params: bitstream.

from board_helpers import overlay
from results import bad, ok, main_entry


def run(p=None):
    p = p or {}
    bit = p.get("bitstream", "base.pdi")
    base = overlay(bit)
    if not base.is_loaded():
        bad("BaseOverlay('%s') did not load the PL" % bit)
        return
    ip = base.ip_dict
    if ip:
        ok("BaseOverlay('%s') loaded; ip_dict has %d IPs" % (bit, len(ip)))
    else:
        bad("BaseOverlay loaded but ip_dict is empty")


if __name__ == "__main__":
    main_entry(run)
