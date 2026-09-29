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

source /etc/profile.d/pynq_venv.sh

# jupyter_server config; hash the default 'xilinx' password.
mkdir -p /root/.jupyter
JHASH=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('xilinx'))")

cat - > /root/.jupyter/jupyter_server_config.py <<EOT
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 9090
c.ServerApp.root_dir = '$PYNQ_JUPYTER_NOTEBOOKS'
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.PasswordIdentityProvider.hashed_password = '${JHASH}'
c.IdentityProvider.token = ''
c.ZMQChannelsWebsocketConnection.iopub_data_rate_limit = 100000000
import datetime
expire_time = datetime.datetime.now() + datetime.timedelta(days=3650)
c.IdentityProvider.cookie_options = {"expires": expire_time}
EOT

# In the past, we would enable widgets here
# As of JupyterLab3 - widgets are now installed with pip

mkdir -p $PYNQ_JUPYTER_NOTEBOOKS

systemctl enable jupyter
