#!/bin/bash

set -e

if mount | grep $PWD/build
then
  echo "Staging area still mounted - please run 'make delete' manually."
  exit 1
fi

if sudo losetup -a | grep rootfs
then
  echo "Loopback device still mounted - please run 'make delete' manually."
  exit 1
fi
