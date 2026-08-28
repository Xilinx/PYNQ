#!/bin/bash
PORT="${PYNQ_REMOTE_PORT:-7967}"
hexport=$(printf ':%04X' "${PORT}")
if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":${PORT}\b"; then
    ok "listening on :${PORT} (ss)"
elif grep -qi "$hexport" /proc/net/tcp /proc/net/tcp6 2>/dev/null; then
    ok "listening on :${PORT} (/proc/net/tcp)"
else
    bad "nothing listening on :${PORT}"
fi
