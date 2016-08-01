#!/bin/bash

rm -rf /home/xilinx/pynq/bitstream/.log
python3.4 /home/xilinx/scripts/start_pl_server.py &

script_name=`readlink -f "$0"`

echo "${script_name}: Programmable Logic server started"
