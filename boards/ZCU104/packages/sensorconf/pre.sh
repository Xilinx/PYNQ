#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# /etc/sensors.d doesn't exist on a minimal noble rootfs. mkdir -p
# before the copy so the cp doesn't fail.
sudo mkdir -p $target/etc/sensors.d/
sudo cp $script_dir/zcu104.conf $target/etc/sensors.d/

