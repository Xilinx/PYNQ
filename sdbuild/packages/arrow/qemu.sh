# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

VERSION=0.16.0
export HOME=/root
export ARROW_HOME=/root/dist
export LD_LIBRARY_PATH=/root/dist/lib:$LD_LIBRARY_PATH
export PARQUET_TEST_DATA=/root/arrow/cpp/submodules/parquet-testing/data
export ARROW_TEST_DATA=/root/arrow/testing/data
url_dist="https://www.xilinx.com/bin/public/openDownload?filename=arrow.${VERSION}.${ARCH}.tar.gz"
url_whl="https://www.xilinx.com/bin/public/openDownload?filename=pyarrow-${VERSION}.${ARCH}.whl"
if [ ${ARCH} == 'arm' ]; then
	md5_dist=38ab303ff3e46534fcce3cf8c8cf51cf
	md5_whl=251564771551ea308b7580b6390429d5
else
	md5_dist=2adc7adc1f97667a860e2aea3272e31d
	md5_whl=ca478d5ce942852c847dbfca6f248457
fi

cd /root
wget -O arrow.tar.gz ${url_dist}
wget -O pyarrow.whl ${url_whl}
if [[ $(md5sum arrow.tar.gz | cut -d' ' -f1) == $md5_dist && 
		$(md5sum pyarrow.whl | cut -d' ' -f1) == $md5_whl ]]; then
	bootstrap=0
else
	bootstrap=1
fi

if [ $bootstrap == 0 ]; then
	# leverage compiled version
	cd /root
	tar -xvf arrow.tar.gz
	cp -rf ${ARROW_HOME}/* /usr/
	python3 -m pip install *.whl
else
	# bootstrapping
	cd /root
	mkdir -p dist
	git clone https://github.com/apache/arrow/
	cd arrow
	git submodule init && git submodule update
	git checkout -b apache-arrow-${VERSION} tags/apache-arrow-${VERSION}
	mv /root/*.patch .
	git apply *.patch

	# build c++ library
	mkdir cpp/build
	cd cpp/build
	cmake -DCMAKE_INSTALL_PREFIX=${ARROW_HOME} \
		-DCMAKE_INSTALL_LIBDIR=lib \
		-DARROW_PYTHON=ON \
		-DARROW_PLASMA=ON \
		-DARROW_BUILD_TESTS=ON \
		-DPYTHON_EXECUTABLE=/usr/bin/python3 \
		..
	make -j4
	make install

	# install library files and python whl
	cd /root/arrow/python
	PYARROW_WITH_PLASMA=1 python3 setup.py bdist_wheel
	python3 -m pip install dist/*.whl
	cp -rf ${ARROW_HOME}/* /usr/
fi

# clean
cd /root
rm -rf *.tar.gz *.whl arrow dist
