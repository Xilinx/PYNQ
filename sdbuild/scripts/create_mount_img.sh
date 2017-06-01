#!/bin/bash

image_file=$1
image_dir=$2
script_dir=$(dirname ${BASH_SOURCE[0]})
truncate --size 7G $image_file
$script_dir/create_partitions.sh $image_file
mount_points=( $(kpartx -av $image_file | cut -d ' ' -f 3) )

echo ${mount_points[0]}
echo ${mount_points[1]}

root_part=/dev/mapper/${mount_points[1]}
boot_part=/dev/mapper/${mount_points[0]}

sleep 1

mkfs -t fat $boot_part
mkfs -t ext4 $root_part

mkdir $image_dir
mount $root_part $image_dir
mkdir $image_dir/boot
mount $boot_part $image_dir/boot
