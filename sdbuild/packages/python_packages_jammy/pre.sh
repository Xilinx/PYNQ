#!/bin/bash

set -x
set -e

target=$1
target_dir=root/.cache/pip
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -d "$script_dir/pre-built/$target_dir" ]
then
    sudo mkdir -p $target/$target_dir
    sudo cp -rf $script_dir/pre-built/$target_dir/* $target/$target_dir
fi

sudo cp $script_dir/requirements.txt $target/root/
