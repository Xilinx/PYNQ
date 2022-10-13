#!/bin/bash

source /etc/profile.d/pynq_venv.sh
source /etc/profile.d/xrt_setup.sh

# Remove any previous versions of the statefile
echo "from pynq import PL" > /tmp/.pynq_clear_statefile.py
echo "PL.reset()" >> /tmp/.pynq_clear_statefile.py

python3 /tmp/.pynq_clear_statefile.py

