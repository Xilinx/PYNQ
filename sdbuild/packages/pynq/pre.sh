#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# copy external board files into the staging area
if [ ${PYNQ_BOARD} != "Unknown" ]; then
	cd ${PYNQ_BOARDDIR}/..
	if [ -d .git ]; then
		sudo mkdir -p $target/home/xilinx/pynq_git/boards
		sudo cp -rf .git $target/home/xilinx/pynq_git/boards
	fi
	if [ ! -d "$BUILD_ROOT/PYNQ/boards/${PYNQ_BOARD}" ]; then
		cp -rf ${PYNQ_BOARDDIR} $BUILD_ROOT/PYNQ/boards/${PYNQ_BOARD}
	fi
fi

# collect all the boards
cd $BUILD_ROOT/PYNQ/boards
if [ ${PYNQ_BOARD} == "Unknown" ]; then
	boards="Pynq-Z1 Pynq-Z2 ZCU104"
else
	boards="${PYNQ_BOARD}"
fi

# build bitstream, microblaze bsp's and binaries
cd $BUILD_ROOT/PYNQ
./build.sh

# copy files from staging area to the qemu environment
sudo mkdir -p $target/home/xilinx/pynq_git
sudo cp -rfL $BUILD_ROOT/PYNQ/.git $target/home/xilinx/pynq_git
sudo cp -rfL $BUILD_ROOT/PYNQ/docs $target/home/xilinx/pynq_git
sudo cp -rfL $BUILD_ROOT/PYNQ/pynq $target/home/xilinx/pynq_git
sudo cp -fL $BUILD_ROOT/PYNQ/*.md $target/home/xilinx/pynq_git
sudo cp -fL $BUILD_ROOT/PYNQ/LICENSE $target/home/xilinx/pynq_git
sudo cp -fL $BUILD_ROOT/PYNQ/THIRD_PARTY_LIC $target/home/xilinx/pynq_git
sudo cp -fL $BUILD_ROOT/PYNQ/*.png $target/home/xilinx/pynq_git
sudo cp -fL $BUILD_ROOT/PYNQ/*.py $target/home/xilinx/pynq_git
sudo cp -fL $BUILD_ROOT/PYNQ/MANIFEST.in $target/home/xilinx/pynq_git

for bd_name in $boards ; do
	cd $BUILD_ROOT/PYNQ/boards/${bd_name}
	sudo mkdir -p $target/home/xilinx/pynq_git/boards/${bd_name}
	sudo cp -rfL notebooks \
		$target/home/xilinx/pynq_git/boards/${bd_name} 2>/dev/null||:
	overlays=`find . -maxdepth 2 -iname 'makefile' -printf '%h\n' | cut -f2 -d"/"`
	for ol in $overlays ; do
		sudo mkdir -p $target/home/xilinx/pynq_git/boards/${bd_name}/$ol
		sudo cp -fL $ol/*.py $ol/*.bit $ol/*.hwh $ol/*.tcl \
			$target/home/xilinx/pynq_git/boards/${bd_name}/$ol 2>/dev/null||:
		sudo cp -rfL $ol/notebooks \
			$target/home/xilinx/pynq_git/boards/${bd_name}/$ol 2>/dev/null||:
	done
done

sudo cp $script_dir/get_revision.sh $target/home/xilinx
sudo cp $script_dir/pl_server.sh $target/usr/local/bin
sudo cp $script_dir/pl_server.service $target/lib/systemd/system
sudo cp $script_dir/pynq_hostname.sh $target/usr/local/bin
sudo cp $script_dir/boardname.sh $target/etc/profile.d
