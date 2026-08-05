#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/eth0 $target/etc/network/interfaces.d

# Allow ping without sudo.
sudo mkdir -p $target/etc/sysctl.d
echo 'net.ipv4.ping_group_range = 0 2147483647' \
    | sudo tee $target/etc/sysctl.d/10-unprivileged-ping.conf >/dev/null
