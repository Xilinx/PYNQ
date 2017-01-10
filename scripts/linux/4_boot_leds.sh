#!/bin/bash

if [ -z "$PYNQ_PYTHON" ]; then
  PYNQ_PYTHON=python3.4
fi

if [ -f /etc/profile.d/python3.6.sh ]; then
  source /etc/profile.d/python3.6.sh
fi

$PYNQ_PYTHON /home/xilinx/scripts/boot.py &
