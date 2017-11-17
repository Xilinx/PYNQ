#!/bin/bash

# Source the environment as the init system won't
set -a
. /etc/environment
set +a
for f in /etc/profile.d/*; do source $f; done

notebook_args=--no-browser
notebook_version=$(jupyter notebook --version | grep -o '^[0-9]*')

if [ $notebook_version -ge 5 ]; then
  notebook_args="$notebook_args --allow-root"
fi

cd ~xilinx
export SHELL=/bin/bash
jupyter notebook $notebook_args > /var/log/jupyter.log  2>&1 &

while ! wget --no-proxy -q -O - http://localhost:9090/ > /dev/null  ; do
  echo "Waiting for Jupyter"
  sleep 1
done

echo "Starting redirect server"
redirect_server &
