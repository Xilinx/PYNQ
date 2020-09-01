#!/bin/bash

# Exit if we encounter any errors
set -e
set -x

ARCH=$1
ROOT_IMAGE=$2

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
case ${ARCH} in
  arm)
    sample=arm-linux-gnueabihf,microblazeel-xilinx-elf
    ;;
  aarch64)
    sample=aarch64-linux-gnu,microblazeel-xilinx-elf
    ;;
  *)
    echo "Unknown arch ${ARCH}"
    exit 1
    ;;

esac

for f in `find $CT_COMPILE_ROOT/native -name bin -maxdepth 2`:
do
  export PATH=$f:$PATH
done

export -n LD_LIBRARY_PATH
# Use cross tools to build the provided configuration
ct-ng $sample
ct-ng build

cd ${ARCH}/microblazeel-xilinx-elf
chmod u+w bin
cd bin

for f in microblazeel-xilinx-elf-*; do
  ln -s $f mb${f#microblazeel-xilinx-elf}
done
