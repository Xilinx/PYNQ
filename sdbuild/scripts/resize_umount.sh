#!/bin/bash

set -e
set -x

# fdisk is in /sbin so let's make sure it's on the PATH
export PATH=/sbin:$PATH

image_dir=$2
image_file=$1

boot_dev=/dev/mapper/$(sudo kpartx -v $image_file | grep -o 'loop[0-9]*p1')
root_dev=/dev/mapper/$(sudo kpartx -v $image_file | grep -o 'loop[0-9]*p2')
root_offset=$(sudo kpartx -v $image_file | grep 'loop[0-9]*p2' | cut -d ' ' -f 6)
sleep 5

sudo umount $image_dir/boot
sudo umount $image_dir

sudo chroot / e2fsck -y -f $root_dev
used_blocks=$(sudo chroot / resize2fs $root_dev -P | tail -n 1 | cut -d : -f 2)
used_size=$(( $used_blocks * 4 ))
new_size=$(( $used_size + (300 * 1024) ))

echo "New size will be $new_size K"


sudo chroot / e2fsck -y -f $root_dev
sudo chroot / resize2fs $root_dev ${new_size}K
sudo chroot / zerofree $root_dev

sleep 5

sudo kpartx -d $image_file

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $1
  d # delete partition
  2 # rootfs partition
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +$(( $new_size * 2 - 1 ))  # New size in 512 byte blocks
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

total_size=$(( ($root_offset / 2) + $new_size ))

truncate -s ${total_size}K $image_file
