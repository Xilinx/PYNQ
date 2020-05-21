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

# checkout a specific version and apply patch
cd /root
mkdir dist
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

# build python whl
cd /root/arrow/python
PYARROW_WITH_PLASMA=1 python3 setup.py bdist_wheel
python3 -m pip install dist/*.whl

# copy library files
cp -rf ${ARROW_HOME}/* /usr/

# clean
cd /root
rm -rf arrow dist
