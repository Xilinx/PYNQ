#!/bin/bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    echo "PRE-FLIGHT FAILED: Python selftests must run as root (use sudo or become root first)" >&2
    exit 2
fi

PYNQ_VENV=/usr/local/share/pynq-venv

if [[ -f /etc/profile.d/pynq_venv.sh ]]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/pynq_venv.sh
elif [[ -f "$PYNQ_VENV/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source "$PYNQ_VENV/bin/activate"
fi

if [[ -f /etc/profile.d/xrt_setup.sh ]]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/xrt_setup.sh
elif [[ -f /usr/local/share/pynq-selftest/lib/xrt_setup.sh ]]; then
    # shellcheck disable=SC1091
    source /usr/local/share/pynq-selftest/lib/xrt_setup.sh
fi

if [[ -z ${XILINX_XRT:-} ]]; then
    echo "PRE-FLIGHT FAILED: XILINX_XRT unset after sourcing xrt_setup.sh" >&2
    exit 2
fi

export PYTHONPATH="/usr/local/share/pynq-selftest/lib:${PYTHONPATH:-}"
exec "$PYNQ_VENV/bin/python" "$@"
