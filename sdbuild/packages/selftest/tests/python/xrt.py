# Verify XRT runtime environment (XILINX_XRT, xbutil/list devices).

# p: manifest params dict for this test (from selftest.json "params").
import os

from results import bad, ok, main_entry


def run(p=None):
    xrt = os.environ.get("XILINX_XRT", "")
    if xrt:
        ok("XILINX_XRT=%s" % xrt)
    else:
        bad("XILINX_XRT is unset (xrt_setup.sh not sourced)")
        return
    try:
        import pyxrt

        pyxrt.device(0)
        ok("pyxrt.device(0) opened an XRT device")
    except Exception as e:
        bad("pyxrt.device(0) failed (XRT env / zocl): %r" % e)


if __name__ == "__main__":
    main_entry(run)
