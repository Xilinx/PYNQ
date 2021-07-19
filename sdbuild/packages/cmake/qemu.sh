# ARMHF needs a new cmake (>3.16.3) to fix its use in 32b QEMU from a 64b host
# 
#
#!/bin/bash

set -x
set -e

cd /usr
./cmake-3.20.5-Linux-armv7l.sh --skip-license
rm cmake-3.20.5-Linux-armv7l.sh
