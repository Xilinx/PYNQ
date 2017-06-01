#!/bin/bash
set -x
set -e

target=$1
image_file=$2

umount $target/boot
umount $target 
sleep 1
kpartx -d $image_file
