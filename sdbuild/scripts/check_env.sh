#!/bin/bash

# Check for dependencies 
read -d '' DEPS_COMMON <<EOT
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
libncurses5-dev
libglib2.0-dev
device-tree-compiler
qemu-user-static
binfmt-support
multistrap
git
lib32z1
lib32ncurses5
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
EOT

#Account for package name differences
read -d '' DEPS_16_04 <<EOT16
gcc-multilib
EOT16

read -d '' DEPS_18_04 <<EOT18
gcc-multilib-arm-linux-gnueabihf
EOT18

if [[ $(lsb_release -rs) == "16.04" ]]; then
    echo "Adding 16.04 DEPS"
    DEPS="$DEPS_COMMON $DEPS_16_04"
else
    # 18.04 and later releases
    echo "Adding 18.04+ DEPS"
    DEPS="$DEPS_COMMON $DEPS_18_04"
fi


if [ $(lsb_release -rs) == "16.04" ]||[ $(lsb_release -rs) == "18.04" ]; then
    echo "Pass: Current OS is supported."
else
    echo "Error: Please use Ubuntu 16.04 or Ubuntu 18.04."
    exit 1
fi

if [ "$EUID" -eq 0 ] ; then
    echo "Error: Please do not run as root."
    exit 1
fi

echo "Checking system for installed $DEPS"

failed=false
for i in $DEPS ; do
    dpkg-query -W -f='${Package}\n' | grep ^$i$ > /dev/null
    if [ $? != 0 ] ; then
        echo "Error: Package not found -" $i
	failed=true
    fi
done 
if [ "$failed" = true ] ; then
    echo "Run setup_host.sh"
    exit 1
fi

