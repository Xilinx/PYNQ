#!/bin/bash
script_dir=$(dirname ${BASH_SOURCE[0]})
set -x
set -e

target=$1
SRCDIR=$2
ARCH=$3

fss="proc dev sys"
echo $QEMU_EXE

multistrap_conf=${SRCDIR}/multistrap.config
multistrap_opt=

if [ -n "$PYNQ_UBUNTU_REPO" ]; then
  tmpfile=$(mktemp)
  export PYNQ_UBUNTU_REPO=$(echo ${PYNQ_UBUNTU_REPO} | sed 's\noble\noble/$(ARCH)\')
  sed -e "s;source=.*;source=${PYNQ_UBUNTU_REPO};" $multistrap_conf > $tmpfile
  mkdir -p $target/etc/apt/apt.conf.d/
  echo 'Acquire::AllowInsecureRepositories "1";' > $target/etc/apt/apt.conf.d/allowinsecure
  multistrap_conf=$tmpfile
  multistrap_opt=--no-auth
  trap "rm -f $tmpfile" EXIT
fi

# multistrap's apt-get update needs the Ubuntu archive keyring to verify the repo.
sudo mkdir -p $target/etc/apt/trusted.gpg.d
sudo cp /usr/share/keyrings/ubuntu-archive-keyring.gpg \
    $target/etc/apt/trusted.gpg.d/ubuntu-archive-keyring.gpg

# Perform the basic bootstrapping of the image
$dry_run sudo -E multistrap -f $multistrap_conf -d $target $multistrap_opt

# Make sure the that the root is still writable by us
sudo chroot / chmod a+w $target

# noble is merged-usr: fold multistrap's split /bin,/sbin,/lib into /usr.
for d in bin sbin lib; do
  if [ -d "$target/$d" ] && [ ! -L "$target/$d" ]; then
    sudo mkdir -p "$target/usr/$d"
    sudo cp -a "$target/$d/." "$target/usr/$d/"
    sudo rm -rf "$target/$d"
    sudo ln -s "usr/$d" "$target/$d"
  fi
done
sudo rm -rf "$target/lib64"
sudo ln -s "usr/lib" "$target/lib64"

# Rewrite multistrap's malformed remove-on-upgrade conffile lines so dpkg can
# parse the status file.
sudo sed -i -E \
    's#^ remove-on-upgrade ([^ ]+)[[:space:]]*$# \1 newconffile remove-on-upgrade#' \
    $target/var/lib/dpkg/status

cat - > $target/postinst1.sh <<EOT
set -x
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
rm -f /var/run/reboot-required
# Configure base-passwd first so the root user exists.
dpkg --configure -a
# multistrap skips base-files; install it from cache (dpkg -i handles the
# usr-merge symlinks), then configure its dependents.
dpkg -i /var/cache/apt/archives/base-files_*.deb
dpkg --configure -a
exit 0
EOT
cat - > $target/postinst2.sh <<EOT
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
rm -f /var/run/reboot-required
rm -f /var/run/firefox-restart-required
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

# Disable wpa_supplicant service so ifup works correctly
systemctl mask wpa_supplicant

# Disable hibernation to keep interfaces alive
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Disable UA Client
systemctl mask ua-auto-attach.service

# Disable apport crash reporter (unused on the appliance; its oneshot fails)
systemctl mask apport.service

# Disable the DHCP server. multistrap pulls isc-dhcp-server in as a dependency
# and Ubuntu's postinst leaves both units enabled, but nothing writes
# /etc/default/isc-dhcp-server unless the usbgadget or wpa_ap package is in the
# board's package list -- so on every other board they just fail at boot.
# usbgadget re-enables the v4 unit after configuring it for usb0.
systemctl disable isc-dhcp-server isc-dhcp-server6

# Disable default graphical environment
systemctl set-default multi-user

# Ensure /usr/local/bin is a directory
mkdir -p /usr/local/bin
EOT

if [ -n "$PYNQ_UBUNTU_REPO" ]; then
  cat - >> $target/postinst2.sh <<EOT
echo "deb http://ports.ubuntu.com/ubuntu-ports noble main universe" > /etc/apt/sources.list.d/multistrap-noble.list
echo "deb-src http://ports.ubuntu.com/ubuntu-ports noble main universe" >> /etc/apt/sources.list.d/multistrap-noble.list
EOT
fi

cat - >> $target/postinst2.sh <<EOT
exit 0
EOT


# Copy over what we need to complete the installation
$dry_run sudo cp ${QEMU_EXE} $target/usr/bin

# Finish the base install
# Pass through special files so that the chroot works properly
for fs in $fss
do
  $dry_run sudo mount -o bind /$fs $target/$fs
done

$dry_run sudo -E chroot $target bash postinst1.sh

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

# Apply base-configuration patches if the release provides any.
if [ -d ${SRCDIR}/patch ]; then
  for f in $(cd ${SRCDIR}/patch && find -name "*.diff")
  do
    $dry_run sudo chroot / patch $target/${f%.diff} < ${SRCDIR}/patch/$f
  done
fi

$script_dir/kill_chroot_processes.sh $target
