# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

# make symlink for gtest
cd /usr/src/gtest
cmake CMakeLists.txt
make
cd /usr/lib
ln -s /usr/src/gtest/libgtest.a
ln -s /usr/src/gtest/libgtest_main.a

# build and install
cd /root
mkdir xrt-git
git clone https://github.com/Xilinx/XRT xrt-git
cd xrt-git
git checkout -b temp tags/2019.1_RC1
mv /root/*.patch .
git apply 0001-fix-for-pynq.patch

cd build
chmod 755 build.sh
./build.sh

# put platform name for xrt app
echo ${PYNQ_BOARD} > /etc/xocl.txt

# cleanup
cd /root
rm -rf xrt-git

