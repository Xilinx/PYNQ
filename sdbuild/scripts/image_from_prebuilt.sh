#! /bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sdbuild_dir="$(dirname $script_dir)"

function usage {
echo "$0 board bsp_file arch prebuilt" >&2
echo "" >&2
echo "Script for generating a board-specific image from a board agnostic prebuilt image" >&2
echo ""
echo "board    : The name of the board" >&2
echo "bsp_file : The BSP file to use" >&2 
echo "arch     : The architecture of the system - either arm or aarch64" >&2
echo "prebuilt : The image to use as a base" >&2

exit 1
}

function checkdeps {
  for f in kpartx zerofree petalinux-config; do
    if ! which $f > /dev/null; then
      echo "Could not find required command $f, please ensure it is installed" 2>&1
      exit 1
    fi
  done 
}

function realpath { echo $(cd $(dirname "$1"); pwd)/$(basename "$1"); }

if [ 4 -ne $# ]; then
  usage
fi

checkdeps

boardname=$1
bsp_file=$2
arch=$3
prebuilt=$4

if ! [ "$arch" = arm -o "$arch" = aarch64 ]; then
  echo "Invalid architecture $arch" >&2
  echo "" >&2
  usage
fi

if ! [ -f "$bsp_file" ]; then
  echo "Could not find BSP $bsp_file" >&2
  exit 1
fi

if ! [ -f "$prebuilt" ]; then
  echo "Could not find image file $prebuilt" >&2
  exit 1
fi

bsp_file="$(realpath $bsp_file)"
prebuilt="$(realpath $prebuilt)"

tempdir=`mktemp -d`
trap "rm -rf $tempdir" EXIT

boarddir=$tempdir/$boardname
mkdir $boarddir
specfile=$boarddir/$boardname.spec
ln -s $bsp_file $boarddir/$boardname.bsp 

echo "Creating spec file for BSP $bsp" >&2

echo "ARCH_$boardname := $arch" > $specfile
echo "BSP_$boardname := $boardname.bsp" >> $specfile

echo "Invoking make" >&2

if ! (cd $sdbuild_dir && make BOARDDIR=$tempdir PREBUILT=$prebuilt nocheck_images); then
  echo "Make failed" >&2
  exit 1
fi

echo "Image is now available in $sdbuild_dir/output" 2>&1

