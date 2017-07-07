#!/bin/bash

# This script sets up a Ubuntu host to be able to create the image by
# installing all of the necessary files. It assumes an EC2 host with
# passwordless sudo

# Install a bunch of packages we need

read -d '' PACKAGES <<EOT
bc
libtool-bin
gperf
bison
flex
texi2html
texinfo
help2man
gawk
libtool
build-essential
automake
libncurses5-dev
libz-dev
libglib2.0-dev
device-tree-compiler
qemu-user-static
binfmt-support
multistrap
git
lib32z1
lib32ncurses5
lib32bz2-1.0
lib32stdc++6
libgnutls-dev
libssl-dev
kpartx
zerofree
u-boot-tools
EOT

sudo apt-get install -y $PACKAGES

# Install up-to-date versions of crosstool and qemu
mkdir tools
cd tools/

wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.bz2
tar -xf crosstool-ng-1.22.0.tar.bz2
cd crosstool-ng/
./configure --prefix=/opt/crosstool-ng
make
sudo make install
cd ..

wget http://wiki.qemu-project.org/download/qemu-2.8.0.tar.bz2
tar -xf qemu-2.8.0.tar.bz2
cd qemu-2.8.0
./configure --target-list=arm-linux-user --prefix=/opt/qemu --static
make
sudo make install
# Create the symlink that ubuntu expects
cd /opt/qemu/bin
sudo ln -s qemu-arm qemu-arm-static
cd ~

# Create gmake symlink to keep SDK happy
cd /usr/bin
sudo ln -s make gmake

echo 'PATH=/opt/qemu/bin:/opt/crosstool-ng/bin:$PATH' >> ~/.profile

echo "Now install Vivado and SDK version 2016.1 and login again to ensure the enviroment is properly set up"
