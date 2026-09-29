# Verify RF-DC radio hierarchy exposes tx/rx channel descriptions.

# p: manifest params dict for this test (from selftest.json "params").
from board_helpers import init_rf_clks, overlay
from results import bad, ok, main_entry


def run(p=None):
    base = overlay()
    init_rf_clks(base)
    txd = base.radio.transmitter.get_channel_description()
    rxd = base.radio.receiver.get_channel_description()
    if txd and rxd:
        ok(
            "RF-DC radio hierarchy usable (%d tx / %d rx channels)"
            % (len(base.radio.transmitter.channel), len(base.radio.receiver.channel))
        )
    else:
        bad("RF-DC channel descriptions came back empty")


if __name__ == "__main__":
    main_entry(run)
