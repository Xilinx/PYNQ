#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_bitstreams () {
	local root=$1
	local board=$2
	local orig_dir=$(pwd)
	cd $root/$board
	local overlays=`find . -maxdepth 2 -name 'makefile' -printf '%h\n' | cut -f2 -d"/"`
	for ol in $overlays ; do
		cd $root/$board/$ol
		if [[ -e $ol.bit && -e $ol.hwh ]]; then
			echo "skipping bitstream $ol.bit for $board"
		else
			echo "building bitstream $ol.bit for $board"
			make
		fi
	done
	cd $orig_dir
}

# build all default bitstreams since they will be included in the sdist
# this happens when we install pynq at stage 3
default_boards="Pynq-Z1 Pynq-Z2 ZCU104"
if [ ${PYNQ_BOARD} = "Unknown" ]; then
	for b in $default_boards ; do
		build_bitstreams "$BUILD_ROOT/PYNQ/boards" "$b"
	done
fi

# build all the microblaze bsp's using Pynq-Z2's hdf
# this happens when we install pynq at stage 3
if [ ${PYNQ_BOARD} = "Unknown" ]; then
	orig_dir=$(pwd)
	cd $BUILD_ROOT/PYNQ/boards/sw_repo
	make HDF=../Pynq-Z2/base/base.hdf HW_DEF=hw_base

	cd bsp_iop_arduino_mb/iop_arduino_mb && rm -rf code libsrc && cd -
	cp -rf bsp_iop_arduino_mb $BUILD_ROOT/PYNQ/pynq/lib/arduino/bsp_iop_arduino
	cd $BUILD_ROOT/PYNQ/pynq/lib/arduino && make && cd $BUILD_ROOT/PYNQ/boards/sw_repo

	cd bsp_iop_pmoda_mb/iop_pmoda_mb && rm -rf code libsrc && cd -
	cp -rf bsp_iop_pmoda_mb $BUILD_ROOT/PYNQ/pynq/lib/pmod/bsp_iop_pmod
	cd $BUILD_ROOT/PYNQ/pynq/lib/pmod && make && cd $BUILD_ROOT/PYNQ/boards/sw_repo

	cd bsp_iop_rpi_mb/iop_rpi_mb && rm -rf code libsrc && cd -
	cp -rf bsp_iop_rpi_mb $BUILD_ROOT/PYNQ/pynq/lib/rpi/bsp_iop_rpi

	make clean && make HDF=../Pynq-Z2/logictools/logictools.hdf HW_DEF=hw_logictools

	cd bsp_lcp_ar_mb/lcp_ar_mb && rm -rf code libsrc && cd -
	cp -rf bsp_lcp_ar_mb $BUILD_ROOT/PYNQ/pynq/lib/logictools/bsp_lcp_ar_mb
	cd $BUILD_ROOT/PYNQ/pynq/lib/logictools && make && cd $BUILD_ROOT/PYNQ/boards/sw_repo

	make clean
	cd $orig_dir
fi

# build missing bitstream, only if any board/overlay can be located
# this happens when we install pynq at stage 4
if [ ${PYNQ_BOARD} != "Unknown" ]; then
	build_bitstreams "$BUILD_ROOT/PYNQ/boards" "${PYNQ_BOARD}"
fi

# copy files, excluding sdist, onto qemu image
# copy default board files at stage 3; copy additional board files at stage 4
if [ ${PYNQ_BOARD} == "Unknown" ]; then
	board_dir="$BUILD_ROOT/PYNQ/boards/Pynq-Z1 \
		   $BUILD_ROOT/PYNQ/boards/Pynq-Z2 \
		   $BUILD_ROOT/PYNQ/boards/ZCU104"
else
	cd ${PYNQ_BOARDDIR}/..
	if [ -d .git ]; then
		sudo cp -rf .git $target/home/xilinx/pynq_git/boards
	fi
	if [ ! -d "$BUILD_ROOT/PYNQ/boards/${PYNQ_BOARD}" ]; then
		cp -rf ${PYNQ_BOARDDIR} $BUILD_ROOT/PYNQ/boards/${PYNQ_BOARD}
	fi
	board_dir="$BUILD_ROOT/PYNQ/boards/Pynq-Z1 \
		   $BUILD_ROOT/PYNQ/boards/Pynq-Z2 \
		   $BUILD_ROOT/PYNQ/boards/ZCU104 \
		   $BUILD_ROOT/PYNQ/boards/${PYNQ_BOARD}"
fi
sudo mkdir -p $target/home/xilinx/pynq_git
sudo cp -rf $BUILD_ROOT/PYNQ/.git $target/home/xilinx/pynq_git
sudo cp -rf $BUILD_ROOT/PYNQ/docs $target/home/xilinx/pynq_git
sudo cp -rf $BUILD_ROOT/PYNQ/pynq $target/home/xilinx/pynq_git
sudo cp -f $BUILD_ROOT/PYNQ/*.md $target/home/xilinx/pynq_git
sudo cp -f $BUILD_ROOT/PYNQ/LICENSE $target/home/xilinx/pynq_git
sudo cp -f $BUILD_ROOT/PYNQ/THIRD_PARTY_LIC $target/home/xilinx/pynq_git
sudo cp -f $BUILD_ROOT/PYNQ/*.png $target/home/xilinx/pynq_git
sudo cp -f $BUILD_ROOT/PYNQ/*.py $target/home/xilinx/pynq_git
sudo cp -f $BUILD_ROOT/PYNQ/MANIFEST.in $target/home/xilinx/pynq_git
for bd_path in $board_dir ; do
	bd_name=`echo $bd_path | rev | cut -f1 -d"/" | rev`
	cd $bd_path
	sudo mkdir -p $target/home/xilinx/pynq_git/boards/${bd_name}
	sudo cp -rf notebooks $target/home/xilinx/pynq_git/boards/${bd_name}
	overlays=`find . -maxdepth 2 -name 'makefile' -printf '%h\n' | cut -f2 -d"/"`
	for ol in $overlays ; do
		sudo mkdir -p $target/home/xilinx/pynq_git/boards/${bd_name}/$ol
		sudo cp -f $ol/*.py $ol/*.bit $ol/*.hwh $ol/*.tcl \
			$target/home/xilinx/pynq_git/boards/${bd_name}/$ol
		sudo cp -rf $ol/notebooks \
			$target/home/xilinx/pynq_git/boards/${bd_name}/$ol
	done
done

sudo cp $script_dir/get_revision.sh $target/home/xilinx
sudo cp $script_dir/pl_server.sh $target/usr/local/bin
sudo cp $script_dir/pl_server.service $target/lib/systemd/system
sudo cp $script_dir/pynq_hostname.sh $target/usr/local/bin
sudo cp $script_dir/boardname.sh $target/etc/profile.d

