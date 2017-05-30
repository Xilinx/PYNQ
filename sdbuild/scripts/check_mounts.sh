#!/bin/bash

if mount | grep $PWD/.build
then
  echo "Staging area currently mounted - please unmount $PWD/.build/rootfs_staging"
  exit 1
fi

if losetup -a | grep rootfs
then
  echo "Loopback device still mounted please use losetup and kpartx to unmount"
  exit 1
fi
