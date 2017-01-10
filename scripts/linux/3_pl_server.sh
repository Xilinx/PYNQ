#!/bin/bash

if [ -z "$PYNQ_PYTHON" ]; then
  PYNQ_PYTHON=python3.4
fi

if [ -f /etc/profile.d/python3.6.sh ]; then
  source /etc/profile.d/python3.6.sh
fi

$PYNQ_PYTHON /home/xilinx/scripts/start_pl_server.py &

script_name=`readlink -f "$0"`

echo "${script_name}: Programmable Logic server started"
