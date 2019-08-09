#!/bin/bash

set -e

mount="/boot"
config_name="wpa_supplicant.conf"
driver_name="wifi.ko"

#use the 1st partition of sdcard
boot_part="/dev/mmcblk0p1"

#mount boot partition to temp folder
mount -o rw "$boot_part" "$mount"

#make sure config file is present
if [ -f "$mount"/"$config_name" ]; then

    #look for custom wifi driver
    if [ -f "$mount"/"$driver_name" ]; then
        rmmod "$mount"/"$driver_name" | true
        insmod "$mount"/"$driver_name"
    fi

fi
