#!/bin/bash

echo "Release $(date +'%Y_%m_%d')"\
	"$(git rev-parse --short=7 --verify HEAD)"
cd /home/xilinx/pynq_git/boards
if [ -d .git ]; then
	echo "Board $(date +'%Y_%m_%d')"\
		"$(git rev-parse --short=7 --verify HEAD)"\
		"$(git config --get remote.origin.url)"
fi
