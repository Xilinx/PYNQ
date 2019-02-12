#!/bin/sh
# Some Copyright Info goes here
# Source the environment as the init system won't
set -a
. /etc/environment
set +a
for f in /etc/profile.d/*; do source $f; done

cd ~root
notebook_args="--no-browser --allow-root"

export SHELL=/bin/bash
export HOME=/home/root
jupyter notebook $notebook_args > /var/log/jupyter.log  2>&1 &
