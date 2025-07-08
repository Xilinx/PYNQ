# Set up some environment variables as /etc/environment
# isn't sourced in chroot

set -e
set -x

. /etc/environment
for f in /etc/profile.d/*.sh; do source $f; done

export HOME=/root
export BOARD=${PYNQ_BOARD}

cd /home/xilinx
mkdir -p jupyter_notebooks

# clone and then install extra packages
python3 -m pip install --upgrade git+https://github.com/Xilinx/PYNQ-Metadata.git
python3 -m pip install --upgrade git+https://github.com/Xilinx/PYNQ-Utils.git

cd pynq_git
python3 -m pip install --upgrade setuptools==59.6.0 
BOARD=${PYNQ_BOARD} PYNQ_JUPYTER_NOTEBOOKS=${PYNQ_JUPYTER_NOTEBOOKS} \
     python3 -m pip install dist/*.tar.gz --upgrade --no-deps --no-use-pep517

# v3.1 - if using prebuilt SDIST, allow current pynq_git contents to
#        override the SDIST python files with current contents (--ignore-installed)
if [ -z "$REBUILD_PYNQ_SDIST" ]; then
    BOARD=${PYNQ_BOARD} PYNQ_JUPYTER_NOTEBOOKS=${PYNQ_JUPYTER_NOTEBOOKS} \
     python3 -m pip install . --upgrade --no-deps --no-use-pep517 --ignore-installed
fi



if [ -d notebooks ]; then
     cp -r notebooks/* ${PYNQ_JUPYTER_NOTEBOOKS}/
fi
cd ..

old_hostname=$(hostname)
pynq_hostname.sh
hostname $old_hostname
rm -rf jupyter_notebooks_*

cd /root

pynq_dir="$(pip3 show pynq | grep '^Location' | cut -d : -f 2)/pynq"
if [ ! -e /home/xilinx/pynq ]; then
  ln -s $pynq_dir /home/xilinx/pynq
fi
chown xilinx:xilinx /home/xilinx/REVISION
chown xilinx:xilinx -R /home/xilinx/pynq
chown xilinx:xilinx -R /home/xilinx/jupyter_notebooks
chown xilinx:xilinx -R $pynq_dir
