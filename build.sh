#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

usage () {
echo "$0" >&2
echo "" >&2
echo "Script for building default overlays, microblaze bsp's and binaries." >&2
echo "" >&2
}

checkdeps () {
for f in vivado vitis; do
	if ! which $f > /dev/null; then
		echo "Could not find command $f, please ensure it is installed" 2>&1
		exit 1
	fi
done
}

# bitstream building will be skipped only if bit and hwh are both available
build_bitstreams () {
	local root=$1
	local board=$2
	local orig_dir=$(pwd)
	cd $root/$board
	local overlays=`find . -maxdepth 2 \
		\( -name 'makefile' \) -or \( -name 'Makefile' \)| cut -f2 -d"/"`
	for ol in $overlays ; do
		cd $root/$board/$ol
		if [[ -e $ol.bit && -e $ol.hwh ]]; then
			echo "skipping bitstream $ol.bit for $board"
		else
			echo "building bitstream $ol.bit for $board"
			make clean
			make
		fi
	done
	cd $orig_dir
}

usage
checkdeps

# enforce Pynq-Z2 projects to be rebuilt in case of missing XSA files
if [[ ! -e $script_dir/boards/Pynq-Z2/base/base.xsa ]]; then
	rm -f $script_dir/boards/Pynq-Z2/base/base.bit
	rm -f $script_dir/boards/Pynq-Z2/base/base.hwh
fi
if [[ ! -e $script_dir/boards/Pynq-Z2/logictools/logictools.xsa ]]; then
	rm -f $script_dir/boards/Pynq-Z2/logictools/logictools.bit
	rm -f $script_dir/boards/Pynq-Z2/logictools/logictools.hwh
fi

# build all bitstreams for all the boards
cd $script_dir/boards
boards=`find . -maxdepth 2 -name '*.spec' -printf '%h\n' | cut -f2 -d"/"`
for b in $boards ; do
	build_bitstreams "$script_dir/boards" "$b"
done
common_path="standalone_domain/bsp"

# build IO Processor (IOP) binaries
if [ ! -d $script_dir/pynq/lib/arduino/bsp_iop_arduino ] || \
	[ ! -d $script_dir/pynq/lib/pmod/bsp_iop_pmod ] || \
	[ ! -d $script_dir/pynq/lib/rpi/bsp_iop_rpi ]; then
	cd $script_dir/boards/sw_repo
	make clean && make XSA=../Pynq-Z2/base/base.xsa

	cd $script_dir/boards/sw_repo
	rm -rf bsp_iop_arduino_mb/iop_arduino_mb/$common_path/iop_arduino_mb/code
	rm -rf bsp_iop_arduino_mb/iop_arduino_mb/$common_path/iop_arduino_mb/libsrc
	cp -rf bsp_iop_arduino_mb/iop_arduino_mb/$common_path \
		$script_dir/pynq/lib/arduino/bsp_iop_arduino
	cd $script_dir/pynq/lib/arduino && make && make clean

	cd $script_dir/boards/sw_repo
	rm -rf bsp_iop_pmoda_mb/iop_pmoda_mb/$common_path/iop_pmoda_mb/code
	rm -rf bsp_iop_pmoda_mb/iop_pmoda_mb/$common_path/iop_pmoda_mb/libsrc
	cp -rf bsp_iop_pmoda_mb/iop_pmoda_mb/$common_path \
		$script_dir/pynq/lib/pmod/bsp_iop_pmod
	cd $script_dir/pynq/lib/pmod && make && make clean

	cd $script_dir/boards/sw_repo
	rm -rf bsp_iop_rpi_mb/iop_rpi_mb/$common_path/iop_rpi_mb/code
	rm -rf bsp_iop_rpi_mb/iop_rpi_mb/$common_path/iop_rpi_mb/libsrc
	cp -rf bsp_iop_rpi_mb/iop_rpi_mb/$common_path \
		$script_dir/pynq/lib/rpi/bsp_iop_rpi

	cd $script_dir/boards/sw_repo
	make clean
fi

# build Logictools Controller Processor (LCP) binaries
if [ ! -d $script_dir/pynq/lib/logictools/bsp_lcp_ar_mb ]; then
	cd $script_dir/boards/sw_repo
	make clean && make XSA=../Pynq-Z2/logictools/logictools.xsa

	cd $script_dir/boards/sw_repo
	rm -rf bsp_lcp_ar_mb/lcp_ar_mb/$common_path/lcp_ar_mb/code
	rm -rf bsp_lcp_ar_mb/lcp_ar_mb/$common_path/lcp_ar_mb/libsrc
	cp -rf bsp_lcp_ar_mb/lcp_ar_mb/$common_path \
		$script_dir/pynq/lib/logictools/bsp_lcp_ar_mb
	cd $script_dir/pynq/lib/logictools && make && make clean

	cd $script_dir/boards/sw_repo
	make clean
fi
