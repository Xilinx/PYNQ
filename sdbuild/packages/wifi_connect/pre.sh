#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/wifi_connect.sh $target/usr/local/bin
sudo cp $script_dir/wifi_connect.service $target/lib/systemd/system

