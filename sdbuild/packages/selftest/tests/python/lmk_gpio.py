# Verify LMK clock-control GPIOs are reachable via dynamic EMIO gpiochip base.
# Params: emio_gpio_addr, lmk_reset_off, lmk_clk_sel0_off, lmk_clk_sel1_off.

# p: manifest params dict for this test (from selftest.json "params").
import glob
import os

from results import FailError, ok, main_entry


def run(p=None):
    p = p or {}
    emio_addr = p.get("emio_gpio_addr")
    if not emio_addr:
        raise FailError("manifest params.emio_gpio_addr required")
    reset_off = int(p.get("lmk_reset_off", 7))
    sel0_off = int(p.get("lmk_clk_sel0_off", 8))
    sel1_off = int(p.get("lmk_clk_sel1_off", 12))

    base = None
    for path in glob.glob("/sys/class/gpio/gpiochip*"):
        if emio_addr in os.path.realpath(path):
            base = int(os.path.basename(path)[len("gpiochip") :])
            break
    if base is None:
        raise FailError(
            "EMIO gpiochip (%s) not present under /sys/class/gpio" % emio_addr
        )

    from pynq import GPIO

    nums = [base + reset_off, base + sel0_off, base + sel1_off]
    handles = []
    try:
        for n in nums:
            handles.append(GPIO(n, "out"))
        ok(
            "LMK control GPIOs addressable via dynamic gpiochip base %d "
            "(reset=+%d, clk_sel0=+%d, clk_sel1=+%d)"
            % (base, reset_off, sel0_off, sel1_off)
        )
    finally:
        del handles
        for n in nums:
            try:
                with open("/sys/class/gpio/unexport", "w") as f:
                    f.write(str(n))
            except OSError:
                pass


if __name__ == "__main__":
    main_entry(run)
