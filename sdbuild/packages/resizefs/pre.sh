#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/resizefs.sh $target/usr/local/bin
sudo cp $script_dir/resizefs.service $target/lib/systemd/system

