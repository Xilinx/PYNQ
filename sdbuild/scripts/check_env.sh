#!/bin/bash

release=$(lsb_release -rs)
if [ "${release}" != "24.04" ]; then
    echo "Error: the build environment is Ubuntu 24.04; found ${release}."
    echo "Build inside the sdbuild Docker container (see sdbuild/README.md)."
    exit 1
fi

# Packages the build itself needs; all are installed by sdbuild/Dockerfile.
read -d '' DEPS <<EOT
bc
gperf
bison
flex
texinfo
help2man
gawk
libtool
libtool-bin
build-essential
automake
device-tree-compiler
qemu-user-static
binfmt-support
multistrap
git
libssl-dev
kpartx
dosfstools
zerofree
u-boot-tools
rpm2cpio
chrpath
socat
zlib1g-dev
unzip
rsync
python3-pip
python3-yaml
crossbuild-essential-arm64
debootstrap
mtools
parted
e2fsprogs
udev
cpio
curl
diffstat
file
gnupg
wget
xz-utils
zstd
lz4
dnsutils
EOT

if [ "$EUID" -eq 0 ] ; then
    echo "Error: Please do not run as root."
    exit 1
fi

if [ ! -f /run/systemd/resolve/stub-resolv.conf ]; then
    sudo mkdir -p /run/systemd/resolve
    sudo cp -L /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf
fi

echo "Checking system for required packages:"
echo $DEPS

failed=false
for i in $DEPS ; do
    dpkg-query -W -f='${Package}\n' | grep ^$i$ > /dev/null
    if [ $? != 0 ] ; then
        echo "Error: Package not found -" $i
        failed=true
    fi
done
if [ "$failed" = true ] ; then
    echo "Rebuild the sdbuild container image to pick up the missing packages."
    exit 1
fi

if [ $(cat /proc/sys/fs/inotify/max_user_watches) -lt 524288 ]; then
    sudo sysctl -n -w fs.inotify.max_user_watches=524288 || \
        echo "Warning: could not raise fs.inotify.max_user_watches"
fi
