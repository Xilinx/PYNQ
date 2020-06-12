# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

export HOME=/root
export JAVA_HOME="$(dirname $(dirname $(realpath $(which javac))))"
VERSION=1.1.0
url="https://www.xilinx.com/bin/public/openDownload?filename=bazel.${VERSION}.${ARCH}"
if [ ${ARCH} == 'arm' ]; then
	md5=43e92758cdd7a3edcb7408deb37803b7
else
	md5=5f9506e2621bc0a6d1ab56576efdcc30
fi

cd /root
wget -O bazel ${url}
if [[ $(md5sum bazel | cut -d' ' -f1) == $md5 ]]; then
	bootstrap=0
else
	bootstrap=1
fi

if [ $bootstrap == 0 ]; then
	# leverage compiled version
	cd /root
	cp -f bazel /usr/local/bin
else
	# download the released source code
	cd /root
	wget https://github.com/bazelbuild/bazel/releases/download/${VERSION}/bazel-${VERSION}-dist.zip
	unzip -d bazel-release bazel-${VERSION}-dist.zip

	# apply patches and build
	chmod u+w bazel-release/* -R
	patch -p0 < bazel-bootstrap.patch
	cd bazel-release
	env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh
	cp -f output/bazel /usr/local/bin/bazel
fi

# cleanup
cd /root
rm -rf bazel *.zip *.patch bazel-release
