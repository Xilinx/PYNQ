#!/bin/bash

if [ -f /etc/default/isc-dhcp-server ] && \
	grep -q "INTERFACES=" /etc/default/isc-dhcp-server; then
	if ! grep -q "wlan1" /etc/default/isc-dhcp-server; then
		sed -i 's/\(INTERFACES=\)"\(.*\)"/\1"\2 wlan1"/g' \
		/etc/default/isc-dhcp-server
	fi
else
	echo 'INTERFACES="wlan1"' > /etc/default/isc-dhcp-server
fi

cat - >> /etc/dhcp/dhcpd.conf <<EOT

subnet 192.168.2.0 netmask 255.255.255.0 {
   option subnet-mask 255.255.255.0;
   option broadcast-address 192.168.2.0;
   range 192.168.2.2 192.168.2.100;
}
EOT

cat - > /etc/network/interfaces.d/wlan0 <<EOT
iface wlan0 inet dhcp
	wireless_mode managed
	wireless_essid any
	wpa-driver wext
	wpa-conf /etc/wpa_supplicant.conf
EOT

# Uncomment the following line to enable wireless access point by default
# systemctl enable wpa_ap.service
