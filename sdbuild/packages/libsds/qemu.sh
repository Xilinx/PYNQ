
export PATH=/opt/python3.6/bin:$PATH
export HOME=/root
export PYNQ_PYTHON=python3.6

cd /root/xlnkutils
make install
cd ..
rm -rf xlnkutils
