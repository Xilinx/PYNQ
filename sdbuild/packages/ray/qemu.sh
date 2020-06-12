# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

export HOME=/root
export JAVA_HOME="$(dirname $(dirname $(realpath $(which javac))))"
VERSION=0.8.3

if [ ${ARCH} == 'arm' ]; then
	url="https://www.xilinx.com/bin/public/openDownload?filename=ray-${VERSION}-cp36-cp36m-linux_armv7l.whl"
	md5=43e92758cdd7a3edcb7408deb37803b7
else
	url="https://www.xilinx.com/bin/public/openDownload?filename=ray-${VERSION}-cp36-cp36m-linux_aarch64.whl"
	md5=5f9506e2621bc0a6d1ab56576efdcc30
fi

cd /root
wget -O ray.whl ${url}
if [[ $(md5sum ray.whl | cut -d' ' -f1) == $md5 ]]; then
	bootstrap=0
else
	bootstrap=1
fi

# use cacerts from host, assuming host has a good java certs
if [ -e /etc/ssl/certs/java/cacerts ]; then
	mv /etc/ssl/certs/java/cacerts /etc/ssl/certs/java/cacerts.qemu
fi
mv /root/cacerts.host /etc/ssl/certs/java/cacerts

if [ $bootstrap == 0 ]; then
	# leverage compiled version
	cd /root
	python3 -m pip install *.whl
else
	# clone from source
	cd /root
	git clone https://github.com/ray-project/ray.git
	cd ray
	git checkout -b temp tags/ray-${VERSION}
	mv /root/*.patch .
	git apply *.patch
	# build and install whl
	cd python
	python3 setup.py bdist_wheel
	python3 -m pip install dist/*.whl
fi

# clean
rm -rf /etc/ssl/certs/java/cacerts
if [ -e /etc/ssl/certs/java/cacerts.qemu ]; then
	mv /etc/ssl/certs/java/cacerts.qemu /etc/ssl/certs/java/cacerts
fi
cd /root
rm -rf *.whl ray
