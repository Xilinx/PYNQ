# Verify PMBus power rails report voltages within nominal ranges.
# Params: rails dict mapping name -> [lo_v, hi_v] from selftest.json.

# p: manifest params dict for this test (from selftest.json "params").
from results import FailError, bad, ok, main_entry


def run(p=None):
    p = p or {}
    rail_ranges = p.get("rails")
    if not rail_ranges:
        raise FailError("manifest params.rails required (name -> [lo, hi] volts)")

    from pynq import get_rails

    rails = get_rails()
    if not rails:
        raise FailError("get_rails() returned no PMBus rails")
    checked = fails = 0
    for name, bounds in rail_ranges.items():
        if name not in rails:
            continue
        lo, hi = float(bounds[0]), float(bounds[1])
        v = rails[name].voltage.value
        checked += 1
        if not (lo <= v <= hi):
            fails += 1
    if checked == 0:
        raise FailError("none of the configured rails found in get_rails()")
    if fails == 0:
        ok("%d/%d PMBus rails within nominal voltage" % (checked, checked))
    else:
        bad("%d/%d PMBus rails out of nominal voltage range" % (fails, checked))


if __name__ == "__main__":
    main_entry(run)
