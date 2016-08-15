#!/bin/bash

# bring up network

ifconfig eth0 down
ifconfig eth0 up
dhclient eth0

# print out IP address
ip=$(echo $(hostname -I))
script_name=`readlink -f "$0"`

echo "${script_name}:        IP Address = ${ip}"
