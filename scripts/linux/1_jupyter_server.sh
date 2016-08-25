#!/bin/bash

su -c 'cd ~xilinx ; jupyter notebook > jupyter.log  2>&1 &' -s /bin/bash root

script_name=`readlink -f "$0"`

echo "${script_name}: Jupyter server started"


