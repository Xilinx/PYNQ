#!/bin/bash

set -x
set -e

for f in /etc/profile.d/*.sh; do source $f; done

mkdir /mnt/fatfs
mount /usr/local/share/fatfs /mnt/fatfs

# HTML version of the Welcome Notebook
if [ -f /usr/local/share/fatfs_contents/Welcome\ to\ Pynq.ipynb ]; then
	jupyter nbconvert --to html \
	/usr/local/share/fatfs_contents/Welcome\ to\ Pynq.ipynb
	rm -f /usr/local/share/fatfs_contents/Welcome\ to\ Pynq.ipynb
	cp -f /usr/local/share/fatfs_contents/Welcome\ to\ Pynq.html \
	/mnt/fatfs
fi

# Copy over the release REVISION
if [ -f /home/xilinx/REVISION ]; then
        cp -f /home/xilinx/REVISION /mnt/fatfs
fi

# Default to USB Gadgets for Windows (RNDIS driver)
touch /mnt/fatfs/delete-for-mac.txt

umount /mnt/fatfs

if [ -f /etc/default/isc-dhcp-server ] && \
	grep -q "INTERFACES=" /etc/default/isc-dhcp-server; then
	if ! grep -q "usb0" /etc/default/isc-dhcp-server; then
		sed -i 's/\(INTERFACES=\)"\(.*\)"/\1"\2 usb0"/g' \
		/etc/default/isc-dhcp-server
	fi
else
	echo 'INTERFACES="usb0"' > /etc/default/isc-dhcp-server
fi

cat - > /etc/dhcp/dhcpd.conf <<EOT
ddns-update-style none;

default-lease-time 600;
max-lease-time 7200;

subnet 192.168.3.0 netmask 255.255.255.0 {
   option subnet-mask 255.255.255.0;
   option broadcast-address 192.168.3.0;
   range 192.168.3.100 192.168.3.150;
}
EOT

systemctl enable usbgadget
systemctl enable serial-getty@ttyGS0
