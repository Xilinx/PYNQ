# Verify USB webcam is detected at /dev/video0.

# p: manifest params dict for this test (from selftest.json "params").
import os
import subprocess

from results import FailError, bad, ok, main_entry


def run(p=None):
    if not os.path.exists("/dev/video0"):
        raise FailError("/dev/video0 absent -- plug in a USB webcam")
    out = "/tmp/pynq-selftest-webcam.jpg"
    subprocess.run(
        ["fswebcam", "--no-banner", "-d", "/dev/video0", "-r", "640x480", "--save", out],
        check=True,
        capture_output=True,
        timeout=25,
    )
    size = os.path.getsize(out) if os.path.exists(out) else 0
    if size > 0:
        ok("USB webcam captured a frame (%d bytes)" % size)
    else:
        bad("USB webcam produced an empty frame")


if __name__ == "__main__":
    main_entry(run)
