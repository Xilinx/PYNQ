#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/show_ip.py $target/usr/local/bin
sudo cp $script_dir/show_ip.service $target/lib/systemd/system

