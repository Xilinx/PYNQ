#!/bin/bash

set +x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ignore=( "*.bsp" "*.dsa" "*.hdf" )
array_contains () {
	local seeking=$1; shift
	local in=1
	for element; do
	if [[ $seeking == $element* ]]; then
		in=0
		break
	fi
	done
	return $in
}

sudo cp -r $BUILD_ROOT/PYNQ $target/home/xilinx/pynq_git
if [ ${PYNQ_BOARD} != "Unknown" ]; then
	cd ${PYNQ_BOARDDIR}/..
	if [ -d .git ]; then
		sudo cp -rf .git $target/home/xilinx/pynq_git/boards
	fi

	cd ${PYNQ_BOARDDIR}
	for f in `find . -type d`
	do
		if [ -e $f/*.xpr ]; then
			ignore+=( $f/ )
		fi
	done
	for f in `find .`
	do
	if ! array_contains "$f" "${ignore[@]}" ; then
		if [ -d $f ]; then
			sudo mkdir -p $target/home/xilinx/pynq_git/boards/${PYNQ_BOARD}/$f
		else
			sudo cp -rf $f $target/home/xilinx/pynq_git/boards/${PYNQ_BOARD}/$f
		fi
	fi
	done
fi
sudo cp $script_dir/pl_server.sh $target/usr/local/bin
sudo cp $script_dir/pl_server.service $target/lib/systemd/system
sudo cp $script_dir/pynq_hostname.sh $target/usr/local/bin
sudo cp $script_dir/boardname.sh $target/etc/profile.d
