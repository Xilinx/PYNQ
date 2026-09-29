# Verify USB3 SuperSpeed link is up.

# p: manifest params dict for this test (from selftest.json "params").
import glob

from results import FailError, ok, main_entry


def run(p=None):
    roots, devices = [], []
    for pth in glob.glob("/sys/bus/usb/devices/*/speed"):
        try:
            with open(pth) as f:
                spd = f.read().strip()
        except OSError:
            continue
        if spd in ("5000", "10000"):
            name = pth.split("/")[-2]
            (roots if name.startswith("usb") else devices).append(name)
    if not roots:
        raise FailError("no SuperSpeed root hub -- USB3 PHY/controller did not come up")
    if devices:
        ok(
            "USB3 up: SuperSpeed root hub present + %d SuperSpeed device(s) linked at >=5 Gbps"
            % len(devices)
        )
    else:
        ok(
            "USB3 up: SuperSpeed root hub present (plug a USB3 device into a USB-A port to link-test)"
        )


if __name__ == "__main__":
    main_entry(run)
