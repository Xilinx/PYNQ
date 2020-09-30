# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

# assume libgtest-dev bootstrapped; remove build dir to keep source clean
cd /usr/src/googletest/googletest
mkdir build
cd build
cmake ..
make
cp *.a /usr/lib/
cd ..
rm -rf build
mkdir -p /usr/local/lib/googletest
ln -s /usr/lib/libgtest.a /usr/local/lib/googletest/libgtest.a
ln -s /usr/lib/libgtest_main.a /usr/local/lib/googletest/libgtest_main.a
