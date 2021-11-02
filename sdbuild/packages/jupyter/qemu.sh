# Set up some environment variables as /etc/environment
# isn't sourced in chroot
set -x
set -e

export HOME=/root
export PYNQ_PYTHON=python3

if [ -z "$PYNQ_JUPYTER_NOTEBOOKS" ]; then
	export PYNQ_JUPYTER_NOTEBOOKS=/home/xilinx/jupyter_notebooks
fi 

if [ ${ARCH} == 'arm' ]; then
	export NODE_OPTIONS=--max-old-space-size=2048
else
	export NODE_OPTIONS=--max-old-space-size=4096
fi

# install nodejs 12
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo deb https://deb.nodesource.com/node_12.x focal main > /etc/apt/sources.list.d/nodesource.list

# TODO fix hang on the apt-get install...
# apt-get update && apt-get install -y nodejs
if [ ${ARCH} == 'arm' ]; then
    wget https://deb.nodesource.com/node_12.x/pool/main/n/nodejs/nodejs_12.22.6-deb-1nodesource1_armhf.deb
    dpkg -i *.deb
    rm -rf *.deb
else
    wget https://deb.nodesource.com/node_12.x/pool/main/n/nodejs/nodejs_12.22.6-deb-1nodesource1_arm64.deb
    dpkg -i *.deb
    rm -rf *.deb
fi

source /etc/profile.d/pynq_venv.sh

jupyter notebook --generate-config --allow-root

cat - >> /root/.jupyter/jupyter_notebook_config.py <<EOT
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.notebook_dir = '$PYNQ_JUPYTER_NOTEBOOKS'
c.NotebookApp.password = 'sha1:46c5ef4fa52f:ee46dad5008c6270a52f6272828a51b16336b492'
c.NotebookApp.port = 9090
c.NotebookApp.iopub_data_rate_limit = 100000000
import datetime
expire_time = datetime.datetime.now() + datetime.timedelta(days=3650)
c.NotebookApp.cookie_options = {"expires": expire_time}
EOT

# In the past, we would enable widgets here
# As of JupyterLab3 - widgets are now installed with pip

mkdir -p $PYNQ_JUPYTER_NOTEBOOKS

systemctl enable jupyter
