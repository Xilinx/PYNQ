#!/bin/bash

set -x
set -e

export HOME=/root

libsigrok_version=0.3.0
libsigrokdecode_version=0.3.0
sigrok_cli_version=0.5.0

libsigrok="libsigrok-${libsigrok_version}"
libsigrokdecode="libsigrokdecode-${libsigrokdecode_version}"
sigrok_cli="sigrok-cli-${sigrok_cli_version}"
patch_file="/libsigrokdecode.diff"

cd $HOME
mkdir sigrok_build
cd sigrok_build

wget http://sigrok.org/download/source/libsigrok/${libsigrok}.tar.gz
tar -xf ${libsigrok}.tar.gz
cd ${libsigrok}
./configure --prefix=/opt/sigrok
make -j 4
make install
cd ..

wget http://sigrok.org/download/source/libsigrokdecode/${libsigrokdecode}.tar.gz
tar -xf ${libsigrokdecode}.tar.gz
cd ${libsigrokdecode}
patch -p2 -i $patch_file
export PKG_CONFIG_PATH=/opt/sigrok/lib/pkgconfig
./configure --prefix=/opt/sigrok
make -j 4
make install
cd ..

echo /opt/sigrok/lib >> /etc/ld.so.conf.d/sigrok.conf
ldconfig

wget http://sigrok.org/download/source/sigrok-cli/${sigrok_cli}.tar.gz
tar -xf ${sigrok_cli}.tar.gz
cd ${sigrok_cli}
./configure --prefix=/opt/sigrok
make -j 4
make install
cd ..

echo 'PATH=/opt/sigrok/bin:$PATH' > /etc/profile.d/sigrok.sh

cd ..

rm -rf sigrok_build
rm -f "$patch_file"
