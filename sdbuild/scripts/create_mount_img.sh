#!/bin/bash
set -e
set -x

image_file=$1
image_dir=$2
script_dir=$(dirname ${BASH_SOURCE[0]})
truncate --size 7G $image_file
$script_dir/create_partitions.sh $image_file
mount_points=( $(sudo kpartx -av $image_file | cut -d ' ' -f 3) )

echo ${mount_points[0]}
echo ${mount_points[1]}

root_part=/dev/mapper/${mount_points[1]}
boot_part=/dev/mapper/${mount_points[0]}

sleep 5

# mkfs wasn't on the list of passwordless sudo commands so work around for now
sudo chroot / mkfs -t fat $boot_part
sudo chroot / mkfs -t ext4 $root_part

mkdir -p $image_dir
sudo mount $root_part $image_dir
sleep 5
# Neither was mkdir
sudo chroot / mkdir $image_dir/boot
sudo mount $boot_part $image_dir/boot
sudo chroot / chmod a+w $image_dir
