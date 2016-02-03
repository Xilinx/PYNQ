#!/bin/bash


jupyter notebook 2> /root/jupyter.log &

script_name=`readlink -f "$0"`

echo "${script_name}: Jupyter server started"


