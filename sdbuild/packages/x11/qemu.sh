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
