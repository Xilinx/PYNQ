# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

export PATH=/opt/python3.6/bin:$PATH
export BOARD=Pynq-Z1
export HOME=/root
export PYNQ_PYTHON=python3.6

cd /home/xilinx
mkdir -p jupyter_notebooks

ln -s /opt/python3.6/lib/python3.6/site-packages/pynq pynq

cd pynq_git
sudo -E pip3.6 install .
cd ..

old_hostname=$(hostname)
pynq_hostname.sh
hostname $old_hostname
rm -rf pynq_git
rm -rf jupyter_notebooks_*

cd /root

chown xilinx:xilinx /home/xilinx/REVISION
chown xilinx:xilinx -R /home/xilinx/pynq
chown xilinx:xilinx -R /home/xilinx/jupyter_notebooks
chown xilinx:xilinx -R $(readlink -f /home/xilinx/pynq)
systemctl enable pl_server
