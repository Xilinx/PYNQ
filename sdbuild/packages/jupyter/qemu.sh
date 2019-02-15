# Set up some environment variables as /etc/environment
# isn't sourced in chroot
set -x
set -e

export PATH=/opt/python3.6/bin:$PATH
export HOME=/root
export PYNQ_PYTHON=python3.6

export HOME=/root
jupyter notebook --generate-config --allow-root

cat - >> /root/.jupyter/jupyter_notebook_config.py <<EOT
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.notebook_dir = '/home/xilinx/jupyter_notebooks'
c.NotebookApp.password = 'sha1:46c5ef4fa52f:ee46dad5008c6270a52f6272828a51b16336b492'
c.NotebookApp.port = 9090
c.NotebookApp.iopub_data_rate_limit = 100000000
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

mkdir -p /home/xilinx/jupyter_notebooks

systemctl enable jupyter
