#!/bin/bash

# User can adjust wlan0 to connect to a specific wifi network
while ! ifconfig wlan0 up
do
  sleep 1
done
. /etc/environment
cd /usr/local/share/wpa_ap

# Create a new managed mode interface wlan1 to run AP
iw phy phy0 interface add wlan1 type managed

hid=$(ifconfig wlan1 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed "s/:/_/g")
ip=192.168.2.1

sed "s/pynq/pynq_$hid/g" wpa_ap.conf > wpa_ap_actual.conf

ifconfig wlan1 down
sleep 2
wpa_supplicant -c ./wpa_ap_actual.conf  -iwlan1 &

ifconfig wlan1 $ip

