# Verify sysfs GPIO interface is available.

# p: manifest params dict for this test (from selftest.json "params").
from results import bad, ok, sh, main_entry


def run(p=None):
    _, labels = sh("cat /sys/class/gpio/gpiochip*/label 2>/dev/null | tr '\\n' ' '")
    if "zynqmp_gpio" in labels.split():
        ok("zynqmp_gpio controller exposed (labels: %s)" % labels)
    else:
        bad("no zynqmp_gpio gpiochip label (labels: %s)" % (labels or "none"))
    try:
        from pynq import GPIO

        base = GPIO.get_gpio_base()
        if base is not None:
            ok("pynq GPIO.get_gpio_base() resolved a base (not None)")
        else:
            bad("pynq GPIO.get_gpio_base() is None")
    except Exception as e:
        bad("pynq GPIO.get_gpio_base() error: %r" % e)


if __name__ == "__main__":
    main_entry(run)
