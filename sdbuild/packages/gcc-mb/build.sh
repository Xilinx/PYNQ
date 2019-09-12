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

SYSROOT_IMAGE=$PWD/sysroot.${ARCH}.img
export HOST_SYSROOT=$PWD/sysroot.${ARCH}
mkdir -p ${HOST_SYSROOT}
cp --sparse=always $ROOT_IMAGE $SYSROOT_IMAGE
${ROOTDIR}/scripts/mount_image.sh $SYSROOT_IMAGE $HOST_SYSROOT

function unmount_delete() {
${ROOTDIR}/scripts/unmount_image.sh $HOST_SYSROOT $SYSROOT_IMAGE
rm $SYSROOT_IMAGE
}

trap unmount_delete EXIT

# Fixup symlinks in the sysroot
(cd $HOST_SYSROOT && for link in `find -lname '/*'`; do target=$(readlink "$link"); sudo rm "$link"; sudo ln -s "$PWD$target" "$link"; done)

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
