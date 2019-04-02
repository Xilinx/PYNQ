
export HOME=/root
export PYNQ_PYTHON=python3.6

cd /root/libcma
make -t
make install
cd ..
rm -rf libcma
