#! /bin/bash

set -x
set -e

. /etc/environment
for f in /etc/profile.d/*.sh; do source $f; done

if [ ${ARCH} == 'arm' ]; then
    export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig
else
    export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
fi

if [ -f /home/xilinx/Welcome\ to\ Pynq.ipynb ]; then
	jupyter nbconvert --to html \
	/home/xilinx/Welcome\ to\ Pynq.ipynb
	rm -f /home/xilinx/Welcome\ to\ Pynq.ipynb
fi

systemctl enable pynq-x11.service
systemctl set-default multi-user

echo startfluxbox > /root/.xinitrc

mkdir /root/armsoc_build
cd /root/armsoc_build

git clone https://anongit.freedesktop.org/git/xorg/driver/xf86-video-armsoc.git -c http.sslverify=false
cd xf86-video-armsoc
git apply /armsoc.patch --ignore-whitespace
git apply /pixmap.patch --ignore-whitespace
./autogen.sh
./configure --prefix=/usr
make -j4
make install
cd /
rm -rf /root/armsoc_build
rm /armsoc.patch
rm /pixmap.patch
