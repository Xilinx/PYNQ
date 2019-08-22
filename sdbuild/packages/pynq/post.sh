#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ${PYNQ_BOARD} != "Unknown" ]; then
	dist_out=$BUILD_ROOT/PYNQ/dist/${PYNQ_BOARD}
	mkdir -p $dist_out
	cp -rf $target/home/xilinx/pynq_git/dist/* $dist_out
fi
sudo rm -rf $target/home/xilinx/pynq_git $target/home/xilinx/get_revision.sh
