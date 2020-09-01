#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/bootpy.sh $target/usr/local/bin
sudo cp $script_dir/boot.py $target/boot/
sudo cp $script_dir/bootpy.service $target/lib/systemd/system

