# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

tag="json-c-0.13.1-20180305"

cd /root
git clone https://github.com/json-c/json-c.git json-c-git
cd json-c-git
git checkout -b tmp tags/${tag}
./autogen.sh
./configure
make
make install
echo "/usr/local/lib" >> /etc/ld.so.conf.d/json-c.conf
ldconfig

cd /root
rm -rf json-c-git
