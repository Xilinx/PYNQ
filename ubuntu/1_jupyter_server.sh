#!/bin/bash

jupyter notebook > /root/jupyter.log 2>&1 &

script_name=`readlink -f "$0"`

echo "${script_name}: Jupyter server started"


