#!/bin/bash
if lsmod 2>/dev/null | grep -q '^zocl'; then
    ok "zocl kernel module loaded"
else
    bad "zocl kernel module not loaded"
fi
if ls /dev/dri/renderD* >/dev/null 2>&1; then
    ok "XRT render node present ($(ls -d /dev/dri/renderD* 2>/dev/null | tr '\n' ' '))"
else
    bad "no /dev/dri/renderD* (zocl device node missing)"
fi
if [[ -e /usr/bin/xbutil ]] || ls /usr/lib/libxrt_core.so* >/dev/null 2>&1; then
    ok "XRT userspace present"
else
    bad "XRT userspace missing"
fi
