# Verify HDMI Tx to Rx loopback through the base overlay.
# Params: bitstream.

import time

import numpy as np

from board_helpers import overlay
from results import bad, ok, params, main_entry


def run(p=None):
    base = overlay((p or {}).get("bitstream"))
    from pynq.lib.video import PIXEL_RGB, VideoMode

    W, H, bw = 1280, 720, 1280 // 8
    bars = np.array(
        [
            [255, 255, 255],
            [255, 255, 0],
            [0, 255, 255],
            [0, 255, 0],
            [255, 0, 255],
            [255, 0, 0],
            [0, 0, 255],
            [0, 0, 0],
        ],
        dtype=np.uint8,
    )
    pattern = np.zeros((H, W, 3), np.uint8)
    for i, c in enumerate(bars):
        pattern[:, i * bw : ((i + 1) * bw if i < 7 else W)] = c

    def bar_means(img):
        return np.array(
            [
                img[:, i * bw + bw // 4 : i * bw + (3 * bw) // 4].reshape(-1, 3).mean(0)
                for i in range(8)
            ]
        )

    ho, hi = base.video.hdmi_out, base.video.hdmi_in
    try:
        hi.frontend.set_hpd(1)
    except Exception:
        pass
    time.sleep(0.5)
    ho.configure(VideoMode(W, H, 24), PIXEL_RGB)
    ho.start()
    f = ho.newframe()
    f[:] = pattern
    ho.writeframe(f)
    time.sleep(1.5)
    hi.configure(PIXEL_RGB)
    hi.start()
    rx = None
    for _ in range(8):
        rx = np.array(hi.readframe())
    tx_m, rx_m = bar_means(pattern), bar_means(rx)
    mad = min(float(np.abs(tx_m - rx_m).mean()), float(np.abs(tx_m - rx_m[:, ::-1]).mean()))
    distinct = float(np.std(rx_m, axis=0).mean())
    try:
        ho.close()
        hi.close()
    except Exception:
        pass
    if mad < 40 and distinct > 40:
        ok("HDMI Tx->Rx loopback recovered the colour bars (MAD=%.1f distinct=%.1f)" % (mad, distinct))
    else:
        bad(
            "HDMI loopback not verified (MAD=%.1f distinct=%.1f; check the Tx->Rx cable)"
            % (mad, distinct)
        )


if __name__ == "__main__":
    main_entry(run)
