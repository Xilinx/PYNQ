#!/bin/bash
script_dir=$(dirname ${BASH_SOURCE[0]})
set -x
set -e

target=$1
SRCDIR=$2

fss="proc dev sys"
echo $QEMU_EXE

multistrap_conf=${SRCDIR}/multistrap.config
multistrap_opt=

if [ -n "$PYNQ_UBUNTU_REPO" ]; then
  tmpfile=$(mktemp)
  sed -e "s;source=.*;source=${PYNQ_UBUNTU_REPO};" $multistrap_conf > $tmpfile
  mkdir -p $target/etc/apt/apt.conf.d/
  echo 'Acquire::AllowInsecureRepositories "1";' > $target/etc/apt/apt.conf.d/allowinsecure
  multistrap_conf=$tmpfile
  multistrap_opt=--no-auth
  trap "rm -f $tmpfile" EXIT
fi

# Perform the basic bootstrapping of the image
$dry_run sudo -E multistrap -f $multistrap_conf -d $target $multistrap_opt

# Make sure the that the root is still writable by us
sudo chroot / chmod a+w $target

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
apt-get clean

rm -f /boot/*

# Create the Xilinx User
adduser --home /home/xilinx xilinx --disabled-password --gecos "Xilinx User,,,,"

echo -e "xilinx\\nxilinx" | passwd xilinx
echo -e "xilinx\\nxilinx" | smbpasswd -a xilinx
echo -e "xilinx\\nxilinx" | passwd root

adduser xilinx adm
adduser xilinx sudo

fake-hwclock save
EOT

if [ -n "$PYNQ_UBUNTU_REPO" ]; then
  cat - >> $target/postinst2.sh <<EOT
echo "deb http://ports.ubuntu.com/ubuntu-ports bionic main universe" > /etc/apt/sources.list.d/multistrap-bionic.list
echo "deb-src http://ports.ubuntu.com/ubuntu-ports bionic main universe" >> /etc/apt/sources.list.d/multistrap-bionic.list
EOT
fi

cat - >> $target/postinst2.sh <<EOT
exit 0
EOT


# Copy over what we need to complete the installation
$dry_run sudo cp ${QEMU_EXE} $target/usr/bin

$dry_run sudo -E chroot $target bash postinst1.sh
# Finish the base install
# Pass through special files so that the chroot works properly
for fs in $fss
do
  $dry_run sudo mount -o bind /$fs $target/$fs
done

function unmount_special() {

# Unmount special files
for fs in $fss
do
  $dry_run sudo umount -l $target/$fs
done
if [ -e "$tmpfile" ]; then
  rm -f $tmpfile
fi
}

trap unmount_special EXIT

$dry_run sudo -E chroot $target bash postinst2.sh

$dry_run rm -f $target/postinst*.sh

# Perform configuration
# Apply patches to the base configuration

for f in $(cd ${SRCDIR}/patch && find -name "*.diff")
do
  # Forgot about patch as well
  $dry_run sudo chroot / patch $target/${f%.diff} < ${SRCDIR}/patch/$f
done

$script_dir/kill_chroot_processes.sh $target
