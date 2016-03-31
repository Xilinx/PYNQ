#!/bin/bash

su -c "jupyter notebook 2> /root/jupyter.log &" -s /bin/bash root

script_name=`readlink -f "$0"`

echo "${script_name}: Jupyter server started"
