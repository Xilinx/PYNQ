#!/bin/bash

if [ -n "${XILINX_TOOLS:-}" ]; then
    for tool in Vivado Vitis; do
        settings="${XILINX_TOOLS}/${tool}/settings64.sh"
        if [ -f "${settings}" ]; then
            # shellcheck source=/dev/null
            source "${settings}"
        fi
    done
    export VIVADO_PATH="${XILINX_TOOLS}/Vivado"
fi

exec "$@"
