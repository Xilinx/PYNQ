#!/bin/bash

# Source the environment as the init system won't
. /etc/environment
notebook_args=
notebook_version=$(jupyter notebook --version | grep -o '^[0-9]*')

if [ $notebook_version -ge 5 ]; then
  notebook_args=--allow-root
fi

cd ~xilinx
jupyter notebook $notebook_args > /var/log/jupyter.log  2>&1 &

