#!/bin/bash

PYNQ_PYTHON=`su -l root bash -c 'echo $PYNQ_PYTHON' 2>/dev/null`

if [ -z "$PYNQ_PYTHON" ]; then
  PYNQ_PYTHON=python3.4
else
  PATH=/opt/$PYNQ_PYTHON/bin:$PATH
fi

$PYNQ_PYTHON /home/xilinx/scripts/boot.py &
