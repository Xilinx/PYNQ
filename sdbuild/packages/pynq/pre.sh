#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp -r $BUILD_ROOT/PYNQ $target/home/xilinx/pynq_git
if [ ${PYNQ_BOARD} != "Unknown" ]; then
	cd ${PYNQ_BOARDDIR}
	for f in `find . ! -name "*.bsp"`
	do
		if [ -d "$f" ]; then
			sudo mkdir -p $target/home/xilinx/pynq_git/boards/${PYNQ_BOARD}/$f
		else
			sudo cp -rf $f $target/home/xilinx/pynq_git/boards/${PYNQ_BOARD}/$f
		fi
	done
fi
sudo cp $script_dir/pl_server.sh $target/usr/local/bin
sudo cp $script_dir/pl_server.service $target/lib/systemd/system
sudo cp $script_dir/pynq_hostname.sh $target/usr/local/bin
sudo cp $script_dir/boardname.sh $target/etc/profile.d
