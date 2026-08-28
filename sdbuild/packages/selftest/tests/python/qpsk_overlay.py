# Verify rfsoc_qpsk QpskOverlay loads and programs the PL.

# p: manifest params dict for this test (from selftest.json "params").
from results import ok, main_entry


def run(p=None):
    from rfsoc_qpsk.qpsk_overlay import QpskOverlay

    QpskOverlay()
    ok("QpskOverlay() programmed the PL (rfsoc_qpsk)")


if __name__ == "__main__":
    main_entry(run)
