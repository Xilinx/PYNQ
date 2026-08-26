# Verify AXI GPIO register_map read/write on LED and button IPs.
# Params: bitstream, led_ip, button_ip, button_mask (optional).

from board_helpers import overlay
from results import FailError, bad, ok, main_entry


def run(p=None):
    p = p or {}
    bit = p.get("bitstream")
    base = overlay(bit)
    led_ip = p.get("led_ip", "axi_gpio_led")
    btn_ip = p.get("button_ip", "axi_gpio_pb")
    try:
        led_gpio = getattr(base, led_ip)
        btn_gpio = getattr(base, btn_ip)
    except AttributeError:
        raise FailError("%s / %s not in overlay" % (led_ip, btn_ip))
    rm = led_gpio.register_map
    rm.GPIO_DATA.CH1_DATA = 0xA
    led_val = int(rm.GPIO_DATA.CH1_DATA)
    btn_val = int(btn_gpio.register_map.GPIO_DATA.CH1_DATA)
    rm.GPIO_DATA.CH1_DATA = 0x0
    if led_val != 0xA:
        bad("register_map LED write/read mismatch: 0x%X" % led_val)
    elif hasattr(base, "buttons"):
        max_val = (1 << len(base.buttons)) - 1
        if 0 <= btn_val <= max_val:
            ok(
                "register_map read/write works "
                "(LED readback=0x%X, buttons CH1_DATA=0x%X)" % (led_val, btn_val)
            )
        else:
            bad(
                "register_map button read out of range: 0x%X (max 0x%X)"
                % (btn_val, max_val)
            )
    else:
        max_val = p.get("button_mask", 0xF)
        if 0 <= btn_val <= max_val:
            ok(
                "register_map read/write works "
                "(LED readback=0x%X, buttons CH1_DATA=0x%X)" % (led_val, btn_val)
            )
        else:
            bad(
                "register_map button read out of range: 0x%X (max 0x%X)"
                % (btn_val, max_val)
            )


if __name__ == "__main__":
    main_entry(run)
