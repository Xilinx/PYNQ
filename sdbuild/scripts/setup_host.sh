#!/bin/bash
set -x
script_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

# This script sets up a Ubuntu host to be able to create the image by
# installing all of the necessary files. It assumes a host with
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
libglib2.0-dev
libfdt-dev
device-tree-compiler
qemu-user-static
binfmt-support
multistrap
git
lib32z1
lib32ncurses5
lib32stdc++6
libssl-dev
kpartx
dosfstools
nfs-common
zerofree
u-boot-tools
rpm2cpio
docker-ce
docker-ce-cli
containerd.io
libsdl1.2-dev
libpixman-1-dev
libc6-dev
chrpath
socat
zlib1g-dev
zlib1g:i386
gcc-multilib
EOT
set -e

sudo apt-get update
sudo apt purge -y libgnutls-dev
sudo dpkg --add-architecture i386
sudo apt-get update
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/ppa
sudo apt-get update
sudo apt-get install -y $PACKAGES

# Double-check docker can run with or without sudo
sudo service docker start
sudo chmod 777 /var/run/docker.sock
docker run hello-world
sudo docker run hello-world

# Install up-to-date versions of crosstool and qemu
if [ -e tools ]; then
  rm -rf tools
fi

mkdir tools
cd tools/

ctver="1.24.0"
wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-$ctver.tar.bz2
tar -xf crosstool-ng-$ctver.tar.bz2
cd crosstool-ng-$ctver
./configure --prefix=/opt/crosstool-ng
make
sudo make install
cd ..

qemuver="4.0.0"
wget http://wiki.qemu-project.org/download/qemu-$qemuver.tar.bz2
tar -xf qemu-$qemuver.tar.bz2
cd qemu-$qemuver
./configure --target-list=arm-linux-user,aarch64-linux-user \
	--prefix=/opt/qemu --static
make && sudo make install
# Create the symlink that ubuntu expects
cd /opt/qemu/bin
sudo rm -rf qemu-arm-static qemu-aarch64-static
sudo ln -s qemu-arm qemu-arm-static
sudo ln -s qemu-aarch64 qemu-aarch64-static
cd ~

# Create gmake symlink to keep SDK happy
cd /usr/bin
if ! which gmake
then
  sudo ln -s make gmake
fi

echo 'PATH=/opt/qemu/bin:/opt/crosstool-ng/bin:$PATH' >> ~/.profile

echo "Now install Vivado, SDK, and Petalinux."
echo "Re-login to  ensure the enviroment is properly set up."
