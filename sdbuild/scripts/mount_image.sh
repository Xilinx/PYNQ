#!/bin/bash

image_file=$1
image_dir=$2
script_dir=$(dirname ${BASH_SOURCE[0]})
mount_points=( $(kpartx -av $image_file | cut -d ' ' -f 3) )

echo ${mount_points[0]}
echo ${mount_points[1]}

root_part=/dev/mapper/${mount_points[1]}
boot_part=/dev/mapper/${mount_points[0]}

sleep 1

mount $root_part $image_dir
mount $boot_part $image_dir/boot

