#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# copy files from staging area to the qemu environment
sudo mkdir -p $target/home/xilinx/pynq_git/boards
sudo mkdir -p $target/home/xilinx/pynq_git/dist

sudo cp $script_dir/pl_server.sh $target/usr/local/bin
sudo cp $script_dir/pl_server.service $target/lib/systemd/system
sudo cp $script_dir/pynq_hostname.sh $target/usr/local/bin
sudo cp $script_dir/boardname.sh $target/etc/profile.d

# add revision file
echo "Release $(date +'%Y_%m_%d') $(git rev-parse --short=7 --verify HEAD)" \
	> $BUILD_ROOT/PYNQ/REVISION

# copy external board files into the staging area
if [ ${PYNQ_BOARD} != "Unknown" ]; then
	cd ${PYNQ_BOARDDIR}
	if git tag > /dev/null 2>&1 && [ $? -eq 0 ]; then
		echo "Board $(date +'%Y_%m_%d')"\
			"$(git rev-parse --short=7 --verify HEAD)"\
			"$(git config --get remote.origin.url)"\
			>> $BUILD_ROOT/PYNQ/REVISION
	fi
	if [ ! -d "$BUILD_ROOT/PYNQ/boards/${PYNQ_BOARD}" ]; then
		cp -rf ${PYNQ_BOARDDIR} $BUILD_ROOT/PYNQ/boards/${PYNQ_BOARD}
	fi
fi

# move revision onto target
sudo cp -rf $BUILD_ROOT/PYNQ/REVISION $target/home/xilinx/REVISION
sudo cp -rf $BUILD_ROOT/PYNQ/REVISION $target/boot/REVISION

if [ -d /usr/local/share/fatfs_contents ]; then
    sudo cp -rf $BUILD_ROOT/PYNQ/REVISION /usr/local/share/fatfs_contents/REVISION
fi

# create sdist
cd $BUILD_ROOT/PYNQ
python3 setup.py sdist
sudo cp dist/*.tar.gz $target/home/xilinx/pynq_git/dist
