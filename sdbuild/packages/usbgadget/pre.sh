#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/usbgadget $target/usr/local/bin
sudo cp $script_dir/usbgadget_stop $target/usr/local/bin
sudo cp $script_dir/usbgadget.service $target/lib/systemd/system
sudo cp $BUILD_ROOT/usbgadget/fatfs $target/usr/local/share
sudo cp -r $script_dir/fatfs $target/usr/local/share/fatfs_contents
if [ -f $BUILD_ROOT/PYNQ/pynq/notebooks/Welcome\ to\ Pynq.ipynb ]; then
	sudo cp -f $BUILD_ROOT/PYNQ/pynq/notebooks/Welcome\ to\ Pynq.ipynb \
	$target/usr/local/share/fatfs_contents
fi
