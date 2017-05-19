#!/bin/bash

set -x
set -e

target=$1

sudo cp -r $WORKDIR/reveal.js $target/root
sudo cp -r $WORKDIR/PYNQ $target/home/xilinx/pynq_git
