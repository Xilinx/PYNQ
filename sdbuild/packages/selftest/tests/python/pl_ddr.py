# Verify PL-attached DDR4 read/write via overlay memory map.
# Params: mem_key (overlay mem_dict key).

# p: manifest params dict for this test (from selftest.json "params").
from board_helpers import overlay
from results import FailError, ok, main_entry
from pynq import MMIO


def run(p=None):
    p = p or {}
    mem_key = p.get("mem_key")
    if not mem_key:
        raise FailError("manifest params.mem_key required")
    base = overlay()
    if mem_key not in base.mem_dict:
        raise FailError("%s not in overlay mem_dict" % mem_key)
    md = base.mem_dict[mem_key]
    mmio = MMIO(md["phys_addr"], md["addr_range"])
    for off, val in ((0x0, 0x12345678), (0x1000, 0xDEADBEEF)):
        mmio.write(off, val)
        rb = mmio.read(off)
        if rb != val:
            raise AssertionError("PL DDR mismatch at 0x%x (wrote 0x%x read 0x%x)" % (off, val, rb))
    ok("PL DDR4 read/write verified (%s)" % mem_key)


if __name__ == "__main__":
    main_entry(run)
