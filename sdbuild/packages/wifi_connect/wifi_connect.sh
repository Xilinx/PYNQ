#!/bin/bash

set -e

mount="/boot"
config_name="wpa_supplicant.conf"

#use the 1st partition of sdcard
boot_part="/dev/mmcblk0p1"

#mount boot partition to temp folder
mount -o rw "$boot_part" "$mount"

#make sure config file is present
if [ -f "$mount"/"$config_name" ]; then
    #find name of wifi interface (assuming first one listed is the one we want)
    wint="$(iw dev | grep 'Interface' | cut -d ' ' -f2 | head -n1)"

    #connect to wifi
    wpa_supplicant -i "$wint" -B -c "$mount"/"$config_name"
    dhclient "$wint"
fi
