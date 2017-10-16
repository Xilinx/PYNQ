#!/bin/bash

# Exit if we encounter any errors
set -e
set -x

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Use cross tools to build the provided configuration
case "$QEMU_EXE" in
  qemu-aarch64-static)
    sample=aarch64-linux-gnu,microblazeel-xilinx-elf
    ;;
  qemu-arm-static)
    sample=arm-linux-gnueabihf,microblazeel-xilinx-elf
    ;;
  *)
    echo "Unknown architecture"
    exit 1
    ;;
esac
ct-ng $sample
ct-ng build

cd microblazeel-xilinx-elf
chmod u+w bin
cd bin

for f in microblazeel-xilinx-elf-*; do
  ln -s $f mb${f#microblazeel-xilinx-elf}
done
