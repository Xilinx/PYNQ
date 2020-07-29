#!/bin/bash
set -x
set -e

target=$1
image_file=$2
used_loop=$(sudo losetup -j $image_file | grep -o 'loop[0-9]*')

sudo umount $target/boot
sudo umount $target
sleep 5
sudo dmsetup remove /dev/mapper/${used_loop}p1
sudo dmsetup remove /dev/mapper/${used_loop}p2
sudo losetup -d /dev/${used_loop}
