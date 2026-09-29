#!/bin/bash
# Sourced by bash selftest modules.

_passed=0
_failed=0
_skipped=0

ok() {
    _passed=$((_passed + 1))
    printf '  [PASS] %s\n' "$1"
}

bad() {
    _failed=$((_failed + 1))
    printf '  [FAIL] %s\n' "$1"
}

skip() {
    _skipped=$((_skipped + 1))
    printf '  [SKIP] %s\n' "$1"
}

read_file() {
    local path=$1
    if [[ -r $path ]]; then
        cat "$path"
    else
        cat "$path" 2>/dev/null || true
    fi
}
