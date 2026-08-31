#!/bin/bash

set -x
set -e

for f in /etc/profile.d/*.sh; do source $f; done

if [ -f /etc/default/isc-dhcp-server ] && \
	grep -q "^INTERFACESv4=" /etc/default/isc-dhcp-server; then
	if ! grep -q "usb0" /etc/default/isc-dhcp-server; then
		sed -i -e 's/^INTERFACESv4="\([^"]\+\)"/INTERFACESv4="\1 usb0"/' \
			-e 's/^INTERFACESv4=""/INTERFACESv4="usb0"/' \
			/etc/default/isc-dhcp-server
	fi
else
	echo 'INTERFACESv4="usb0"' >> /etc/default/isc-dhcp-server
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

systemctl enable isc-dhcp-server
systemctl enable usbgadget
systemctl enable serial-getty@ttyGS0
