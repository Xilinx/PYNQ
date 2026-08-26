#!/bin/bash
PORT="${PYNQ_REMOTE_PORT:-7967}"
if systemctl is-active --quiet pynq-remote 2>/dev/null; then
    ok "pynq-remote.service active"
else
    bad "pynq-remote.service not active"
fi
