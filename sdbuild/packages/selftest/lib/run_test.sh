#!/bin/bash
# Run one selftest module. Invoked by orchestrator.py.
set -euo pipefail

ROOT=${SELFTEST_ROOT:-/usr/local/share/pynq-selftest}
TEST_ID=$1
TIMEOUT=${2:-30}
# Quoted, or the closing brace is literal and gets appended to whatever $3 holds:
# an empty default then looks right while real params arrive as invalid JSON.
PARAMS=${3:-"{}"}
HARDWARE=${4:-false}
RUN_HW=${5:-true}

if [[ $HARDWARE == true && $RUN_HW != true ]]; then
    echo "  [SKIP] hardware check skipped (--no-peripherals)"
    exit 0
fi

resolve_test() {
    local id=$1
    local path=""
    case "$id" in
        bash/*)
            path="$ROOT/tests/${id}.sh"
            ;;
        python/*)
            path="$ROOT/tests/${id}.py"
            ;;
        *)
            path="$ROOT/tests/${id}.sh"
            if [[ ! -f $path ]]; then
                path="$ROOT/tests/${id}.py"
            fi
            ;;
    esac
    if [[ ! -f $path ]]; then
        echo "  [FAIL] test file not found for id ${id} (${path})" >&2
        exit 1
    fi
    printf '%s' "$path"
}

TEST_PATH=$(resolve_test "$TEST_ID")
export SELFTEST_PARAMS="$PARAMS"
export SELFTEST_ROOT="$ROOT"

if [[ $TEST_PATH == *.sh ]]; then
    run=(bash -c "source '$ROOT/lib/results.sh'; source '$TEST_PATH'; \
if (( _failed > 0 )); then exit 1; elif (( _skipped > 0 )); then exit 2; else exit 0; fi")
else
    run=("$ROOT/lib/run_python.sh" "$TEST_PATH")
fi

if command -v timeout >/dev/null 2>&1; then
    run=(timeout --signal=TERM "$TIMEOUT" "${run[@]}")
fi

# `|| rc=$?` because a failing test must be reported, and `set -e` would
# otherwise end the script here with the message below never printed.
rc=0
"${run[@]}" || rc=$?
if [[ $rc -eq 124 ]]; then
    echo "  [FAIL] timed out after ${TIMEOUT}s"
    exit 1
fi
exit $rc
