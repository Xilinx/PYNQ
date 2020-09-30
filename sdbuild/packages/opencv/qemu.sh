# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

version=3.4.3
url=https://www.xilinx.com/bin/public/openDownload?filename=opencv-${version}.${ARCH}.zip
if [ ${ARCH} == 'arm' ]; then
	md5=286d6acccc7ae99c52ce962098e0609e
else
	md5=7561c8066848ac4f92c0e74c7cd9a9e0
fi

cd /root
wget -O opencv.zip ${url}
if [[ $(md5sum opencv.zip | cut -d' ' -f1) == $md5 ]]; then
	bootstrap=0
else
	bootstrap=1
fi

# either extract from released binary, or build from source
if [ $bootstrap == 0 ]; then
	cd /root
	unzip opencv.zip
else
	cd /root
	wget -O opencv.zip \
		https://github.com/opencv/opencv/archive/${version}.zip  
	wget -O opencv_contrib.zip \
		https://github.com/opencv/opencv_contrib/archive/${version}.zip
	unzip opencv.zip
	unzip opencv_contrib.zip
	mkdir opencv-${version}/build
	cd opencv-${version}/build
	cmake -D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_INSTALL_PREFIX=/root/opencv-dist \
		-D BUILD_WITH_DEBUG_INFO=OFF \
		-D BUILD_DOCS=OFF \
		-D BUILD_EXAMPLES=OFF \
		-D BUILD_TESTS=OFF \
		-D BUILD_opencv_ts=OFF \
		-D BUILD_PERF_TESTS=OFF \
		-D INSTALL_C_EXAMPLES=OFF \
		-D INSTALL_PYTHON_EXAMPLES=OFF \
		-D ENABLE_NEON=ON \
		-D WITH_LIBV4L=ON \
		-D WITH_GSTREAMER=ON \
		-D BUILD_opencv_dnn=OFF \
		-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${version}/modules \
		../
	make -j4
	make install
fi

# compiled libs stored in opencv-dist
cd /root
cp -rf opencv-dist/* /usr/local/
echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf
ldconfig
rm -rf *.zip *.txt
rm -rf opencv-${version} opencv_contrib-${version}
rm -rf opencv-dist
