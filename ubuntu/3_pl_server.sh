#!/bin/bash

python3.4 /home/xpp/scripts/pl_server.py &

script_name=`readlink -f "$0"`

echo "${script_name}: Programmable Logic server started"
