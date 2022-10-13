#!/bin/bash

# Add PYNQ Peripherals Drivers and Notebooks

set -e
set -x

. /etc/environment
for f in /etc/profile.d/*.sh; do source $f; done

pip install git+https://github.com/Xilinx/PYNQ_peripherals.git

# TODO pynq CLI depends on XRT, XRT not working in QEMU when `xbutil dump` called
# pynq get-notebooks pynq_peripherals -p $PYNQ_JUPYTER_NOTEBOOKS
mkdir -p $PYNQ_JUPYTER_NOTEBOOKS/pynq_peripherals
cp -r /usr/local/share/pynq-venv/lib/python3.10/site-packages/pynq_peripherals/notebooks/* \
  $PYNQ_JUPYTER_NOTEBOOKS/pynq_peripherals
  
