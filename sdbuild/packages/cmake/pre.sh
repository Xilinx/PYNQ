# ARMHF needs a new cmake (>3.16.3) to fix its use in 32b QEMU from a 64b host
# 
#
#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

wget https://www.xilinx.com/bin/public/openDownload?filename=cmake-3.20.5-Linux-armv7l.sh \
    -O $script_dir/pre-built/cmake-3.20.5-Linux-armv7l.sh

chmod a+x $script_dir/pre-built/cmake-3.20.5-Linux-armv7l.sh
sudo cp -rf $script_dir/pre-built/cmake-3.20.5-Linux-armv7l.sh $target/usr

# TODO should build on x86_64 host using sdcard sysroot
# Build steps below

# on 32b ARM (10's of minutes to build)
# wget https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5.tar.gz
# cmake .  -D_FILE_OFFSET_BITS=64
# cpack -C "Release" -G "STGZ"
