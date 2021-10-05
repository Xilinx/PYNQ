#!/bin/bash

. /etc/environment
for f in /etc/profile.d/*.sh; do source $f; done

BOOT_MNT=/boot
BOOT_DEV=/dev/mmcblk0p1
BOOT_PY=$BOOT_MNT/boot.py

if !(mount | grep -q "$BOOT_MNT") ; then
   mount $BOOT_DEV $BOOT_MNT
fi

if test -f "$BOOT_PY"; then
   python3 $BOOT_PY
fi

