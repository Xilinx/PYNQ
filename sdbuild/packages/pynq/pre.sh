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

if [ -n "$PYNQ_SDIST" ] && [ "$BOARDDIR" -ef "$DEFAULT_BOARDDIR" ]; then
	# using prebuilt sdist with non-external board
	# nothing to do except copy sdist to target folder
	sudo cp ${PYNQ_SDIST} $target/home/xilinx/pynq_git/dist
else
	if [ -n "$PYNQ_SDIST" ] && [ ! "$BOARDDIR" -ef "$DEFAULT_BOARDDIR" ]; then
		# using prebuilt sdist with external board
		# copy bitstreams, microblaze bsps and binaries from sdist
		sdist_untar=$BUILD_ROOT/PYNQ/sdist_untar
		mkdir -p ${sdist_untar}
		tar -xzvf ${PYNQ_SDIST} -C ${sdist_untar}
		cd $BUILD_ROOT/PYNQ
		rsync -rptL --ignore-existing ${sdist_untar}/*/pynq/lib/* pynq/lib/
		boards=`ls ${sdist_untar}/*/boards`
		for bd_name in $boards ; do
			cd ${sdist_untar}/*/boards/${bd_name}
			overlays=`find . -maxdepth 2 -iname '*.bit' -printf '%h\n' | cut -f2 -d"/"`
			for ol in $overlays ; do
				sudo cp -fL $ol/*.bit $ol/*.hwh \
					$BUILD_ROOT/PYNQ/boards/${bd_name}/$ol 2>/dev/null||:
			done
		done
		rm -rf ${sdist_untar}
	fi
	# build bitstream, microblazes' bsps and binaries
	cd $BUILD_ROOT/PYNQ
	./build.sh
	# get rid of Vivado temp files in case there are any
	boards=`find boards -maxdepth 2 -name '*.spec' -printf '%h\n' | cut -f2 -d"/"`
	for bd_name in $boards ; do
		cd $BUILD_ROOT/PYNQ/boards/${bd_name}
		overlays=`find . -maxdepth 2 -iname 'makefile' -printf '%h\n' | cut -f2 -d"/"`
		for ol in $overlays ; do
			cd $BUILD_ROOT/PYNQ/boards/${bd_name}/$ol
			make clean
			if [[ -e $ol.bit.link ]]; then
				rm -f $ol.bit
			fi
			if [[ -e $ol.hwh.link ]]; then
				rm -f $ol.hwh
			fi
		done
	done
	# create sdist
	cd $BUILD_ROOT/PYNQ
	python3 setup.py sdist
	sudo cp dist/*.tar.gz $target/home/xilinx/pynq_git/dist
fi
