#! /bin/bash
# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

set -x
set -e

. /etc/environment
export HOME=/root
export BOARD=${PYNQ_BOARD}

apt install -y libsysfs-dev

cd /root/xsdfec_build

source /usr/local/share/pynq-venv/bin/activate

make embeddedsw
make
make install

cd /root
rm -rf xsdfec_build
