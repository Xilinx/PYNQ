#!/bin/bash

set -x
set -e

target=$1

xsa_path=$BUILD_ROOT/$PYNQ_BOARD/petalinux_project/project-spec/hw-description/system.xsa

hwh_name=$(unzip -p $xsa_path sysdef.xml | xmllint --xpath 'string(/Project/File[@Type="HW_HANDOFF" and @BD_TYPE="DEFAULT_BD"]/@Name)' -)
bin_name=${hwh_name%hwh}bin

(cd $target/boot && sudo unzip $xsa_path $hwh_name)
sudo touch $target/boot/$bin_name

sudo tee -a $target/boot/boot.py <<EOT
import pynq
ol = pynq.Overlay('/boot/$bin_name', download=False)
pynq.Device.active_device.reset(ol.parser, ol.timestamp, ol.bitfile_name)
EOT
