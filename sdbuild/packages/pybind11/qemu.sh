set -x
set -e

VERSION=2.5.0
cd /root
wget "https://github.com/pybind/pybind11/archive/v${VERSION}.zip"
unzip v${VERSION}.zip
cd pybind11-${VERSION}
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_PREFIX_PATH=/usr/local/include/python3.6 \
	..
make -j
make install
echo "/usr/local/lib" >> /etc/ld.so.conf.d/pybind11.conf
ldconfig

cd /root
rm -rf *.zip pybind11-${VERSION}
