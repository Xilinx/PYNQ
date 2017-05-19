#!/bin/bash

export HOME=/root

set -x
set -e

cd $HOME
mkdir opencv_build
cd opencv_build

wget https://github.com/Itseez/opencv/archive/3.1.0.zip
unzip 3.1.0.zip

cd opencv-3.1.0
mkdir build
cd build

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/opencv -DPYTHON3_EXECUTABLE=/opt/python3.6/bin/python3.6 -DPYTHON3_INCLUDE_DIR=/opt/python3.6/include/python3.6m/ -DPYTHON3_LIBRARY=/opt/python3.6/lib/libpython3.6m.so -DPYTHON3_NUMPY_INCLUDE_DIRS=/opt/python3.6/lib/python3.6/site-packages/numpy/core/include -DPYTHON3_PACKAGES_PATH=/opt/python3.6/lib/python3.6/site-packages -DENABLE_NEON=ON ..

make -j4 install

echo /opt/opencv/lib > /etc/ld.so.conf.d/opencv.conf
ldconfig

cd ..
cd ..
cd ..
rm -rf opencv_build
