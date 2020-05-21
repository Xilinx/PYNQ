# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

export HOME=/root
export JAVA_HOME="$(dirname $(dirname $(realpath $(which javac))))"
VERSION=0.8.3

# use cacerts from host, assuming host has a good java certs
if [ -e /etc/ssl/certs/java/cacerts ]; then
	mv /etc/ssl/certs/java/cacerts /etc/ssl/certs/java/cacerts.qemu
fi
mv /root/cacerts.host /etc/ssl/certs/java/cacerts

# clone from source
cd /root
git clone https://github.com/ray-project/ray.git
cd ray
git checkout -b temp tags/ray-${VERSION}
mv /root/*.patch .
git apply *.patch

# build whl for later use if needed
cd python
python3 setup.py bdist_wheel
python3 -m pip install dist/*.whl

# clean
rm -rf /etc/ssl/certs/java/cacerts
if [ -e /etc/ssl/certs/java/cacerts.qemu ]; then
	mv /etc/ssl/certs/java/cacerts.qemu /etc/ssl/certs/java/cacerts
fi
cd /root
rm -rf ray
