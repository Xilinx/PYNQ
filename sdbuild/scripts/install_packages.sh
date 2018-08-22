#!/bin/bash

set -e
set -x

target=$1
shift

fss="proc run dev"


for fs in $fss
do
  $dry_run sudo mount -o bind /$fs $target/$fs
done
mkdir -p $target/ccache
sudo mount -o bind $CCACHEDIR $target/ccache

function unmount_special() {

# Unmount special files
for fs in $fss
do
  $dry_run sudo umount -l $target/$fs
done
sudo umount -l $target/ccache
rmdir $target/ccache || true
}

trap unmount_special EXIT

export CFLAGS="${IMAGE_CFLAGS}"
export CPPFLAGS="$CFLAGS"
export PATH="/usr/lib/ccache:$PATH"
export CCACHE_DIR=/ccache
export CCACHE_MAXSIZE=15G
export CCACHE_SLOPPINESS=file_macro,time_macros
export CC=/usr/lib/ccache/gcc
export CXX=/usr/lib/ccache/g++

for p in $@ 
do
  if [ -n "$PACKAGE_PATH" -a -e $PACKAGE_PATH/$p ]; then
    f=$PACKAGE_PATH/$p
  else
    f=$ROOTDIR/packages/$p
  fi
  if [ -e $f/pre.sh ]; then
    $dry_run $f/pre.sh $target
  fi
  if [ -e $f/qemu.sh ]; then
    $dry_run cp $f/qemu.sh $target
    $dry_run sudo -E chroot $target bash qemu.sh
    $dry_run rm $target/qemu.sh
  fi
  if [ -e $f/post.sh ]; then
    $dry_run $f/post.sh $target
  fi
done

