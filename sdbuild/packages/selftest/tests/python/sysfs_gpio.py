# Verify sysfs GPIO interface is available.

from results import bad, ok, sh, main_entry


def run(p=None):
    label = (p or {}).get("label")
    if not label:
        bad("manifest params.label required")
        return
    _, labels = sh("cat /sys/class/gpio/gpiochip*/label 2>/dev/null | tr '\\n' ' '")
    if label in labels.split():
        ok("%s controller exposed (labels: %s)" % (label, labels))
    else:
        bad("no %s gpiochip label (labels: %s)" % (label, labels or "none"))
    try:
        from pynq import GPIO

        base = GPIO.get_gpio_base(label)
        if base is not None:
            ok("pynq GPIO.get_gpio_base(%r) resolved a base (not None)" % label)
        else:
            bad("pynq GPIO.get_gpio_base(%r) is None" % label)
    except Exception as e:
        bad("pynq GPIO.get_gpio_base(%r) error: %r" % (label, e))


if __name__ == "__main__":
    main_entry(run)
