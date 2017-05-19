#!/bin/bash
set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cp -r $WORKDIR/gcc-mb/microblazeel-xilinx-elf $target/opt
chown root:root -R $target/opt/microblazeel-xilinx-elf
