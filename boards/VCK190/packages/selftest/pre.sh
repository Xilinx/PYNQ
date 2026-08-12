#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo install -D -m 0755 "$script_dir/pynq-selftest" "$target/usr/local/bin/pynq-selftest"
