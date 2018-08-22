#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo chroot / patch $target/usr/bin/phantomjs < $script_dir/phantomjs.patch
