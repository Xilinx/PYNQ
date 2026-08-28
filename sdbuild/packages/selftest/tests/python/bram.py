# Verify AXI BRAM read/write via the loaded overlay.
# Params: bitstream, bram_ip (default axi_bram_ctrl_0).

from board_helpers import overlay
from results import FailError, bad, ok, main_entry


def run(p=None):
    p = p or {}
    bit = p.get("bitstream")
    base = overlay(bit)
    bram_name = p.get("bram_ip", "axi_bram_ctrl_0")
    try:
        bram = getattr(base, bram_name).mmio
    except AttributeError:
        raise FailError("%s not in overlay" % bram_name)
    bram.write(0x00, 0xDEADBEEF)
    bram.write(0x04, 0xCAFEBABE)
    v0, v1 = bram.read(0x00), bram.read(0x04)
    if v0 == 0xDEADBEEF and v1 == 0xCAFEBABE:
        ok("BRAM read/write verified (0xDEADBEEF / 0xCAFEBABE)")
    else:
        bad("BRAM read-back mismatch (got 0x%08X / 0x%08X)" % (v0, v1))


if __name__ == "__main__":
    main_entry(run)
