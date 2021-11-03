#! /bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo cp $script_dir/xorg.conf $target/etc/X11/
sudo cp $script_dir/pynq-x11.service $target/lib/systemd/system
sudo cp $script_dir/armsoc.patch $target/
sudo cp $script_dir/pixmap.patch $target/

snap known --remote model series=16 brand-id=generic model=generic-classic > /tmp/model

sudo snap prepare-image --snap chromium --snap core18 --snap "gnome-3-28-1804" --snap "gtk-common-themes" --snap bare --classic --arch arm64 /tmp/model $target

rm /tmp/model

sudo chroot / mkdir -p $target/root/.config/midori
sudo cp $script_dir/midori_config $target/root/.config/midori/config
sudo cp -r $script_dir/fluxbox_config $target/root/.fluxbox
sudo chroot / mkdir -p $target/usr/local/share/x11
sudo cp $script_dir/pynq-background.png $target/usr/local/share/x11
sudo chroot / mkdir -p $target/home/xilinx/.config/chromium/Default
sudo cp $script_dir/chromium_config $target/home/xilinx/.config/chromium/Default/Preferences
sudo chroot / touch "$target/home/xilinx/.config/chromium/First Run"
sudo cp $script_dir/killchromium $target/usr/bin
if [ -f $BUILD_ROOT/PYNQ/pynq/notebooks/Welcome\ to\ Pynq.ipynb ]; then
	sudo cp -f $BUILD_ROOT/PYNQ/pynq/notebooks/Welcome\ to\ Pynq.ipynb \
	$target/home/xilinx/
fi
