#!/bin/bash

set -e
set -x

image_dir=$2
image_file=$1

boot_dev=/dev/mapper/$(sudo kpartx -v $image_file | grep -o 'loop[0-9]p1')
root_dev=/dev/mapper/$(sudo kpartx -v $image_file | grep -o 'loop[0-9]p2')
root_offset=$(sudo kpartx -v $image_file | grep 'loop[0-9]p2' | cut -d ' ' -f 6)

sudo umount $image_dir/boot

used_blocks=$(sudo resize2fs $root_dev -P | tail -n 1 | cut -d : -f 2)
used_size=$(( $used_blocks * 4 ))
new_size=$(( $used_size + (300 * 1024) ))

echo "New size will be $new_size K"

sudo umount $image_dir

sudo e2fsck -f $root_dev
sudo resize2fs $root_dev ${new_size}K
sudo zerofree $root_dev

sudo kpartx -d $image_file

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk $1
  d # delete partition
  2 # rootfs partition
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +$(( $new_size * 2 ))  # New size in 512 byte blocks
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

total_size=$(( ($root_offset / 2) + $new_size ))

sudo truncate -s ${total_size}K $image_file
