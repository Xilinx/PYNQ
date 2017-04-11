#!/bin/bash

# Source the environment as the init system won't
. /etc/environment
notebook_args=
notebook_version=$(jupyter notebook --version | grep -o '^[0-9]*')

if [ $notebook_version -ge 5 ]; then
  notebook_args=--allow-root
fi

su -c "cd ~xilinx ; jupyter notebook $notebook_args > /var/log/jupyter.log  2>&1 &" -s /bin/bash root

script_name=`readlink -f "$0"`

echo "${script_name}: Jupyter server started"


