#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/boot_leds.sh $target/usr/local/bin
sudo cp $script_dir/flash_leds.py $target/usr/local/bin
sudo cp $script_dir/boot_leds.service $target/lib/systemd/system

