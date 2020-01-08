# Set up some environment variables as /etc/environment
# isn't sourced in chroot
set -x
set -e

export HOME=/root
export PYNQ_PYTHON=python3.6
export PYNQ_JUPYTER_NOTEBOOKS=/home/xilinx/jupyter_notebooks

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

# Enable widgets
jupyter nbextension enable --py --sys-prefix widgetsnbextension
# Install Extensions
jupyter contrib nbextension install --user
jupyter nbextensions_configurator enable --user
jupyter nbextension install rise --py --sys-prefix
jupyter nbextension enable rise --py --sys-prefix
# Enable jupyterlab
jupyter serverextension enable jupyterlab

jupyter labextension install @jupyter-widgets/jupyterlab-manager@1.0.2 --no-build
jupyter labextension install plotlywidget@1.1.0 --no-build
jupyter labextension install jupyterlab-plotly@1.1.0 --no-build

if [ ${ARCH} == 'arm' ]; then
  sed 's:4096:2048:g' -i /usr/local/lib/python3.6/dist-packages/jupyterlab/staging/package.json
fi

jupyter lab build --minimize=False
rm -rf /usr/local/share/jupyter/lab/staging

mkdir -p $PYNQ_JUPYTER_NOTEBOOKS

systemctl enable jupyter
