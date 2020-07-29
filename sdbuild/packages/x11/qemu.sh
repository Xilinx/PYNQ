#! /bin/bash

set -x
set -e

if [ -f /usr/local/share/x11/Welcome\ to\ Pynq.ipynb ]; then
	jupyter nbconvert --to html \
	/usr/local/share/x11/Welcome\ to\ Pynq.ipynb
	rm -f /usr/local/share/x11/Welcome\ to\ Pynq.ipynb
fi

systemctl enable pynq-x11.service

chown -R xilinx:xilinx /home/xilinx/.config/chromium
chmod a+x /usr/bin/killchromium
rm -rf /home/xilinx/.config/chromium/Singleton*

mkdir /root/armsoc_build
cd /root/armsoc_build

git clone https://anongit.freedesktop.org/git/xorg/driver/xf86-video-armsoc.git
cd xf86-video-armsoc
git apply /armsoc.patch --ignore-whitespace
./autogen.sh
./configure --prefix=/usr
make -j4
make install
cd /
rm -rf /root/armsoc_build
rm /armsoc.patch
