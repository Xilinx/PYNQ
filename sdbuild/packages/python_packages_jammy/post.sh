#!/bin/bash

set -x
set -e

target=$1
target_dir=root/.cache/pip
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo mkdir -p $script_dir/pre-built/$target_dir
sudo cp -rf $target/$target_dir/wheels $script_dir/pre-built/$target_dir

# clean cache to save space ~150MB on v2.7
sudo rm -rf $target/$target_dir
