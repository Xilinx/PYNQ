#!/bin/bash

#
target=$1

# Kill all processes in the chroot
for f in /proc/*
do
  if [ -e $f/root -a x`readlink -f $f/root` == x`readlink -f $target` ]
  then
    $dry_run kill `basename $f`
  fi
done
