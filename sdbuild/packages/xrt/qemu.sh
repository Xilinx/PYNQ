# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x


# build and install
cd /root
mkdir xrt-git
git clone https://github.com/Xilinx/XRT xrt-git
cd xrt-git
git checkout -b temp tags/202010.2.6.655

cd build
chmod 755 build.sh
XRT_NATIVE_BUILD=no ./build.sh -dbg
cd Debug
make install

# put platform name for xrt app
echo ${PYNQ_BOARD} > /etc/xocl.txt

# cleanup
cd /root
rm -rf xrt-git

