#!/bin/bash

. /etc/environment

if [ -z "$PYNQ_PYTHON" ]; then
	PYNQ_PYTHON=python3.4
else
	PATH=/opt/$PYNQ_PYTHON/bin:$PATH
fi


BOOT_MNT=/boot
BOOT_DEV=/dev/mmcblk0p1

if [[ ! -d "$BOOT_MNT" ]]
then
    mkdir $BOOT_MNT
fi

mount $BOOT_DEV $BOOT_MNT
$PYNQ_PYTHON $BOOT_MNT/boot.py
umount $BOOT_MNT


