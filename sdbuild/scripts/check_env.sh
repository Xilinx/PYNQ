#!/bin/bash

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
gcc-multilib
EOT

if [ "$EUID" -eq 0 ] ; then
    echo "error: Please do not run as root."
    exit 1
fi

failed=false
for i in $DEPS ; do
    dpkg-query -W -f='${Package}\n' | grep ^$i$ > /dev/null
    if [ $? != 0 ] ; then
        echo "error: Package not found -" $i
	failed=true
    fi
done 
if [ "$failed" = true ] ; then
    echo "Run setup_host.sh"
    exit 1
fi

