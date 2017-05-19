#!/bin/bash

script_dir=$(dirname ${BASH_SOURCE[0]})
target=$1

$dry_run rm -f $target/usr/bin/${QEMU_EXE}

$script_dir/kill_chroot_processes.sh $target
