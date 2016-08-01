#!/bin/bash

# bring up network
source /etc/environment

generate_mac ()  {
  hexchars="0123456789abcdef"
  echo "24:df:86$(
    for i in {1..6}; do
      echo -n ${hexchars:$(( $RANDOM % 16 )):1}
    done | sed -e 's/\(..\)/:\1/g'
  )"
}

if [[ ${MACID} == "" ]]; then
	MACID=$(generate_mac)
	echo "Random MACID generated!"
	echo "MACID=${MACID}" | tee -a /etc/environment
else
	echo "Enabling MACID=${MACID}"
fi

ifconfig eth0 down
ifconfig eth0 hw ether ${MACID}
ifconfig eth0 up
dhclient eth0

# print out IP address
ip=$(echo $(hostname -I))
script_name=`readlink -f "$0"`

echo "${script_name}:        IP Address = ${ip}"
