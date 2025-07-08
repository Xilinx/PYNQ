#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# PYNQv3.1 XRT Patch needed for 32b ARM
sudo cp -f $script_dir/0001-size_t-32b-fix.patch $target/
