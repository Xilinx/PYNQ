#!/bin/bash
if [[ -d /sys/class/fpga_manager/fpga0 ]]; then
    ok "fpga_manager present ($(cat /sys/class/fpga_manager/fpga0/state 2>/dev/null))"
else
    bad "/sys/class/fpga_manager/fpga0 missing"
fi
