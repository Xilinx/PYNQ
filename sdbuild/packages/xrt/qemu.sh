# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x


# build and install
cd /root
mkdir xrt-git
git clone https://github.com/Xilinx/XRT xrt-git
cd xrt-git
git checkout -b temp tags/202020.2.8.726

# An incorrect format specifier causes a crash on armhf
sed -i 's:%ld bytes):%lld bytes):' src/runtime_src/tools/xclbinutil/XclBinClass.cxx

cd build
chmod 755 build.sh
XRT_NATIVE_BUILD=no ./build.sh -dbg
cd Debug
make install

cd ..
mkdir xclbinutil_build
cd xclbinutil_build/
cmake ../../src/
make install -C runtime_src/tools/xclbinutil
mv /opt/xilinx/xrt/bin/unwrapped/xclbinutil /usr/local/bin/xclbinutil
rm -rf /opt/xilinx/xrt

# put platform name for xrt app
echo ${PYNQ_BOARD} > /etc/xocl.txt

# cleanup
cd /root
rm -rf xrt-git

