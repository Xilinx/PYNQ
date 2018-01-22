#!/bin/bash
script_dir=$(dirname ${BASH_SOURCE[0]})

set -x
set -e

target=$1

board=$(cat ${WORKDIR}/board)
fss="proc dev"

# Make sure that our version of QEMU is on the PATH
export PATH=/opt/qemu/bin:$PATH

# Perform the basic bootstrapping of the image
$dry_run multistrap -f ${WORKDIR}/multistrap.config -d $target --no-auth
$dry_run cp ${WORKDIR}/*.deb $target/var/cache/apt/archives

cat - > $target/postinst1.sh <<EOT
/var/lib/dpkg/info/dash.preinst install
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
/var/lib/dpkg/info/dash.preinst install
dpkg --configure -a
exit 0
EOT
cat - > $target/postinst2.sh <<EOT
/var/lib/dpkg/info/dash.preinst install
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
dpkg --configure -a
rm -rf /var/run/*
dpkg --configure -a
# Horrible hack to work around some resolvconf weirdness
apt-get -y --force-yes purge resolvconf
apt-get -y --force-yes install resolvconf

cd /var/cache/apt/archives
dpkg -i $KERNEL_IMAGE_DEB
dpkg -i $KERNEL_HEADER_DEB

apt-get clean

rm -f /boot/*

# Create the Xilinx User
adduser --home /home/xilinx xilinx --disabled-password --gecos "Xilinx User,,,,"

echo -e "xilinx\\nxilinx" | passwd xilinx
echo -e "xilinx\\nxilinx" | smbpasswd -a xilinx
echo -e "xilinx\\nxilinx" | passwd root
echo "BOARD=${board}" >> /etc/environment

adduser xilinx adm
adduser xilinx sudo

fake-hwclock save

exit 0
EOT

# Copy over what we need to complete the installation
$dry_run cp `which ${QEMU_EXE}` $target/usr/bin

$dry_run chroot $target bash postinst1.sh
# Finish the base install
# Pass through special files so that the chroot works properly
for fs in $fss
do
  $dry_run mount -o bind /$fs $target/$fs
done

function unmount_special() {

# Unmount special files
for fs in $fss
do
  $dry_run umount -l $target/$fs
done

}

trap unmount_special EXIT

$dry_run chroot $target bash postinst2.sh

$dry_run rm -f $target/postinst*.sh

# Perform configuration
# Apply patches to the base configuration

for f in $(cd ${WORKDIR}/config_diff && find -name "*.diff")
do
  $dry_run sudo patch $target/${f%.diff} < ${WORKDIR}/config_diff/$f
done

$script_dir/kill_chroot_processes.sh $target
