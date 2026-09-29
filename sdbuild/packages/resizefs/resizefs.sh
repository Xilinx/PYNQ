#!/bin/bash
# Resize the root filesystem to fill the SD card on first boot. Run as root if
# running manually.
exec >> /var/log/syslog
exec 2>&1

TGTDEV=/dev/mmcblk0
TGTPART=/dev/mmcblk0p2
TGTPARTNUM=2
source /etc/environment

if [[ ${RESIZED} -eq "1" ]]; then
	echo "filesystem already resized!"
	exit 0
fi

# Extend partition 2 to fill the disk, then grow the ext4 online.
growpart ${TGTDEV} ${TGTPARTNUM}
partx -u ${TGTPART}
resize2fs ${TGTPART}
echo "RESIZED=1" | tee -a /etc/environment

echo "Adding Swap"
fallocate -l 512M /var/swap
chmod 600 /var/swap
mkswap /var/swap
echo "/var/swap none swap sw 0 0" >> /etc/fstab
swapon /var/swap

echo "Done!"
