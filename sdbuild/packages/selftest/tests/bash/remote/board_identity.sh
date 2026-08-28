#!/bin/bash
if [[ -e /proc/device-tree/chosen/pynq_board ]]; then
    ok "pynq_board = $(tr -d '\0' < /proc/device-tree/chosen/pynq_board)"
else
    bad "/proc/device-tree/chosen/pynq_board missing (host get_board_name() -> Unknown)"
fi
