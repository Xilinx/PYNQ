#!/bin/bash

set -e

mount="/boot"
config_name="wpa_supplicant.conf"

#use fdisk to list devices, fine the one with "*" under Boot and filter out ram
boot_part="$(fdisk -l | awk '/\*/' | grep -v '512' | cut -d ' ' -f1)"

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