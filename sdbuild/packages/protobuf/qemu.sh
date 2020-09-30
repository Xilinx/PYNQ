# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

version=3.9.2
url=https://www.xilinx.com/bin/public/openDownload?filename=protobuf-${version}.${ARCH}.zip
if [ ${ARCH} == 'arm' ]; then
	md5=fe11351b543bed1944731b0a599b8c85
else
	md5=ebacb7138c913a299f45de1fae94dce6
fi

cd /root
wget -O protobuf.zip ${url}
if [[ $(md5sum protobuf.zip | cut -d' ' -f1) == $md5 ]]; then
	bootstrap=0
else
	bootstrap=1
fi

# either extract from released binary, or build from source
if [ $bootstrap == 0 ]; then
	cd /root
	unzip protobuf.zip
else
	cd /root
	mkdir -p /root/protobuf-dist
	git clone https://github.com/protocolbuffers/protobuf.git protobuf-git
	cd protobuf-git
	git checkout -b temp tags/v${version}
	git submodule update --init --recursive
	./autogen.sh
	./configure --with-protoc=protoc --prefix=/root/protobuf-dist
	make -j4
	make install
fi

# compiled libs stored in protobuf-dist
cd /root
cp -rf protobuf-dist/* /usr/local/
echo "/usr/local/lib" >> /etc/ld.so.conf.d/protobuf.conf
ldconfig
cd /root
rm -rf *.zip *.txt
rm -rf protobuf-git protobuf-dist
