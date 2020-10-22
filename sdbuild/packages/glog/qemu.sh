export HOME=/root

set -x
set -e

VERSION=0.4.0
cd /root
wget https://github.com/google/glog/archive/v${VERSION}.zip
unzip v${VERSION}.zip
cd glog-${VERSION}
mkdir -p build
cd build
cmake -DBUILD_SHARED_LIBS=on \
	-DCMAKE_INSTALL_PREFIX=/usr/local \
	-DCMAKE_BUILD_TYPE=Release \
	..
make -j
make install
echo "/usr/local/lib" >> /etc/ld.so.conf.d/glog.conf
ldconfig

cd /root
rm -rf *.zip glog-${VERSION}

