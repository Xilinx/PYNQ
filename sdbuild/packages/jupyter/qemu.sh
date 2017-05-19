# Set up some environment variables as /etc/environment
# isn't sourced in chroot

export PATH=/opt/python3.6/bin:$PATH
export BOARD=Pynq-Z1
export HOME=/root
export PYNQ_PYTHON=python3.6

export HOME=/root
jupyter notebook --generate-config --allow-root

cat - >> /root/.jupyter/jupyter_notebook_config.py <<EOT
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.nbserver_extensions = {"jupyterlab":True}
c.NotebookApp.notebook_dir = '/home/xilinx/jupyter_notebooks'
c.NotebookApp.password = 'sha1:46c5ef4fa52f:ee46dad5008c6270a52f6272828a51b16336b492'
c.NotebookApp.port = 9090
EOT

# Enable widgets
jupyter nbextension enable --py --sys-prefix widgetsnbextension
# Install Extensions
jupyter contrib nbextension install --user
jupyter nbextensions_configurator enable --user

