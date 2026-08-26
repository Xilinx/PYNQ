# Verify removed legacy libraries (arduino, rpi, logictools) are absent.

# p: manifest params dict for this test (from selftest.json "params").
import importlib.util

from results import bad, ok, main_entry


def run(p=None):
    for mod in ("arduino", "rpi", "logictools"):
        absent = importlib.util.find_spec("pynq.lib.%s" % mod) is None
        if absent:
            ok("pynq.lib.%s absent" % mod)
        else:
            bad("pynq.lib.%s still present" % mod)


if __name__ == "__main__":
    main_entry(run)
