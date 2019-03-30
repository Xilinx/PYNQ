#!/bin/bash
set -x
set -e

target=$1
image_file=$2

sudo umount $target/boot
sudo umount $target
sleep 5
sudo kpartx -d $image_file
