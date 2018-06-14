#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp -r $BUILD_ROOT/PYNQ $target/home/xilinx/pynq_git
if [ ${PYNQ_BOARD} != "Unknown" ]; then
	sudo cp -rf ${PYNQ_BOARDDIR} \
	$target/home/xilinx/pynq_git/boards/
fi
sudo cp $script_dir/pl_server.sh $target/usr/local/bin
sudo cp $script_dir/pl_server.service $target/lib/systemd/system
sudo cp $script_dir/pynq_hostname.sh $target/usr/local/bin
sudo cp $script_dir/boardname.sh $target/etc/profile.d
