export HOME=/root

set -x
set -e


# Captured using pip3 freeze on image after packages installed with no versions
cd /root
cat > requirements.txt <<EOT
alabaster==0.7.12
anyio==3.1.0
argon2-cffi==20.1.0
async-generator==1.10
Babel==2.9.1
backcall==0.2.0
bleach==3.3.0
Brotli==1.0.9
cffi==1.14.5
click==8.0.1
CppHeaderParser==2.7.4
Cython==0.29.24
dash==2.0.0
dash-bootstrap-components==0.13.1
dash-core-components==2.0.0
dash-html-components==2.0.0
dash-renderer==1.9.1
dash-table==5.0.0
defusedxml==0.7.1
deltasigma==0.2.2
docutils==0.17.1
Flask==2.0.1
Flask-Compress==1.10.1
gTTS==2.2.3
imagesize==1.2.0
imutils==0.5.4
ipykernel==5.5.5
ipython==7.24.0
ipywidgets==7.6.3
itsdangerous==2.0.1
jedi==0.17.2
Jinja2==3.0.1
json5==0.9.5
jsonschema==3.2.0
jupyter==1.0.0
jupyter-client==6.1.12
jupyter-console==6.4.0
jupyter-contrib-core==0.3.3
jupyter-contrib-nbextensions==0.5.1
jupyter-core==4.7.1
jupyter-highlight-selected-word==0.2.0
jupyter-latex-envs==1.4.6
jupyter-nbextensions-configurator==0.4.1
jupyter-server==1.8.0
jupyterlab==3.0.16
jupyterlab-pygments==0.1.2
jupyterlab-server==2.5.2
jupyterlab-widgets==1.0.0
jupyterplot==0.0.3
lrcurve==1.1.0
MarkupSafe==2.0.1
matplotlib-inline==0.1.2
mistune==0.8.4
nbclassic==0.3.1
nbclient==0.5.3
nbconvert==6.0.7
nbformat==5.1.3
nbsphinx==0.8.7
nbwavedrom==0.2.0
nest-asyncio==1.5.1
netifaces==0.11.0
notebook==6.4.0
numpy==1.20.3
pandas==1.3.3
pandocfilters==1.4.3
parsec==3.9
parso==0.7.1
patsy==0.5.1
pbr==5.6.0
pexpect==4.8.0
pip==21.2.1
pkg_resources==0.0.0
plotly==5.1.0
prometheus-client==0.10.1
prompt-toolkit==3.0.18
psutil==5.8.0
ptyprocess==0.7.0
PyAudio==0.2.11
pybind11==2.8.0
pycairo==1.20.1
pycurl==7.43.0.2
pyeda==0.28.0
Pygments==2.9.0
pyrsistent==0.17.3
pyzmq==22.1.0
qtconsole==5.1.0
QtPy==1.9.0
rise==5.7.1
roman==3.3
Send2Trash==1.5.0
setproctitle==1.2.2
setuptools==44.0.0
simplegeneric==0.8.1
sniffio==1.2.0
snowballstemmer==2.1.0
SpeechRecognition==3.8.1
Sphinx==4.2.0
sphinx-rtd-theme==1.0.0
sphinxcontrib-applehelp==1.0.2
sphinxcontrib-devhelp==1.0.2
sphinxcontrib-htmlhelp==2.0.0
sphinxcontrib-jsmath==1.0.1
sphinxcontrib-qthelp==1.0.3
sphinxcontrib-serializinghtml==1.1.5
tenacity==8.0.0
terminado==0.10.0
testpath==0.5.0
testresources==2.0.1
tornado==6.1
tqdm==4.62.3
traitlets==5.0.5
voila==0.2.10
voila-gridstack==0.2.0
websocket-client==1.0.1
Werkzeug==2.0.1
widgetsnbextension==3.5.1
wurlitzer==3.0.2
EOT

export PYNQ_VENV=/usr/local/share/pynq-venv

python3 -m venv --system-site-packages $PYNQ_VENV
echo "source $PYNQ_VENV/bin/activate" > /etc/profile.d/pynq_venv.sh
source /etc/profile.d/pynq_venv.sh

python3 -m pip install pip==21.2.4
python3 -m pip install -r requirements.txt
rm requirements.txt
