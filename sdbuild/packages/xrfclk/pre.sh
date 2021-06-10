#!/bin/bash
# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

set -e
set -x

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp -r $script_dir/package $target/root/xrfclk_build

if [${BOARD} == "ZCU111"]; then
cat $script_dir/boot.py | sudo tee -a $target/boot/boot.py
fi
