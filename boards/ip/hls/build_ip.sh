#!/bin/bash

# check if y2k22 patch has been applied
if [ ! -f $XILINX_HLS/common/scripts/automg_patch_20220104.tcl ]; then
	echo "Please make sure you have applied the y2k22 patch to your installation"
	echo "https://support.xilinx.com/s/article/76960?language=en_US"
fi

for f in */script.tcl
do
  vitis_hls -f $f
done
