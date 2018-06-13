#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/wpa_ap.service $target/lib/systemd/system
sudo cp -r $script_dir/wpa_ap $target/usr/local/share/
