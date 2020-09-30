#!/bin/bash
script_dir=$(dirname ${BASH_SOURCE[0]})
set -x
set -e

board=$1
template=$2

if [ -n "$BSP" ]; then
	# If $BSP is a URL, fetch it!
	if [[ "$BSP" == *"://"* ]] ; then
		BSP_ABS="${BSP_BUILD}/../downloaded-${BSP_PROJECT}.bsp"
		curl -o "${BSP_ABS}" "${BSP}"
		BSP=$(basename "${BSP_ABS}")
	fi
	cp -f $BSP_ABS $BSP_BUILD
	cd $BSP_BUILD
	old_project=$(echo $(tar -xvf $BSP) | cut -f1 -d" ")
	rm -f $BSP
	cd $old_project
	rm -rf components hardware pre-built
	if [ -d "$board/petalinux_bsp/meta-user" ]; then
		cp -rf $board/petalinux_bsp/meta-user/* \
			$BSP_BUILD/$old_project/project-spec/meta-user
	fi
	cd $BSP_BUILD
	tar -czvf $BSP_PROJECT.bsp $old_project
else
	cp -rf $board/petalinux_bsp/* $BSP_BUILD
	cd $BSP_BUILD/hardware_project
	if [ -e "makefile" ]; then make; fi
	cd $BSP_BUILD
	petalinux-create --type project --template $template --name $BSP_PROJECT
	cd $BSP_PROJECT
	petalinux-config --get-hw-description=$BSP_BUILD/hardware_project \
		--silentconfig
	if [ -d "$board/petalinux_bsp/meta-user" ]; then
		cp -rf $board/petalinux_bsp/meta-user/* \
			$BSP_BUILD/$BSP_PROJECT/project-spec/meta-user
	fi
	cd $BSP_BUILD
	petalinux-package --force --bsp -p $BSP_PROJECT \
		--output $BSP_PROJECT.bsp
fi
