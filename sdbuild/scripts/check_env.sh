#!/bin/bash

if [ $(lsb_release -rs) == "18.04" ]; then
    rel_deps="libncurses5-dev lib32ncurses5"
elif [ $(lsb_release -rs) == "20.04" ]; then
    rel_deps="libncurses6 lib32ncurses6"
else
    echo "Error: Please use Ubuntu 20.04 or Ubuntu 18.04."
    exit 1
fi

# Check for dependencies 
read -d '' DEPS <<EOT
bc
gperf
bison
flex
texi2html
texinfo
help2man
gawk
libtool
libtool-bin
build-essential
automake
libglib2.0-dev
device-tree-compiler
qemu-user-static
binfmt-support
multistrap
git
lib32z1
libbz2-1.0
lib32stdc++6
libssl-dev
kpartx
zerofree
u-boot-tools
rpm2cpio
libsdl1.2-dev
rsync
python3-pip
gcc-multilib
libidn11
curl
${rel_deps}
EOT

read -d '' PYTHON_DEPS <<EOT
numpy
cffi
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
for i in $PYTHON_DEPS ; do
    found=$(sudo -H python3 -m pip freeze | grep $i)
    if [ -z $found ]; then
        echo "Error: Package not found -" $i
        failed=true
    fi
done
if [ "$failed" = true ] ; then
    echo "Run setup_host.sh"
    exit 1
fi

if [ $(cat /proc/sys/fs/inotify/max_user_watches) -lt 524288 ]; then
    sudo sysctl -n -w fs.inotify.max_user_watches=524288
    echo "Set inotify max_user_watches to 524288"
fi
