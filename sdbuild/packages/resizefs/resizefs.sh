#!/bin/bash
# This script is used to resize the ubuntu image to fill up the entire
# space available in the SDCard. Run as root if running manually.
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
exec >> /var/log/syslog
exec 2>&1

TGTDEV=/dev/mmcblk0
TGTPART=/dev/mmcblk0p2
source /etc/environment

if [[ ${RESIZED} -eq "1" ]]; then
	echo "filesystem already resized!"
	exit 0
fi

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV} 2>/dev/null
	p # print the in-memory partition table
	d # delete
	2 # second partition
	n #  new partition
	p # primary partition
	2 # second partition
	  # default first sector
	  # fill up the entire space
	p # print the new partition table
  	w # and we're done
EOF

partx -u ${TGTPART}
resize2fs ${TGTPART}
echo "RESIZED=1" | tee -a /etc/environment
echo "Adding Swap"

fallocate -l 1G /var/swap
mkswap /var/swap
echo "/var/swap none swap sw 0 0" >> /etc/fstab
swapon /var/swap

echo "Done!"
