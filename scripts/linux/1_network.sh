#!/bin/bash

# bring up network
ifconfig eth0 down
ifconfig eth0 up
dhclient eth0

# Add static IP
ifconfig eth0:1 192.168.2.99 netmask 255.255.255.0

# Force ntp update
systemctl stop ntp
ntpdate 0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org\
        2.ubuntu.pool.ntp.org 3.ubuntu.pool.ntp.org
systemctl start ntp

# print out IP address
ip=$(echo $(hostname -I))
script_name=`readlink -f "$0"`

echo "${script_name}:        IP Address = ${ip}"
