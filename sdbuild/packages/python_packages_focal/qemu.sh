export HOME=/root

set -x
set -e


# Captured using pip3 freeze on image after packages installed with no versions
cd /root
cat > requirements.txt <<EOT
anyio==3.1.0
argon2-cffi==20.1.0
async-generator==1.10
atomicwrites==1.1.5
attrs==19.3.0
Babel==2.9.1
backcall==0.2.0
bleach==3.3.0
blinker==1.4
certifi==2019.11.28
cffi==1.14.5
chardet==3.0.4
click==8.0.1
cryptography==2.8
cycler==0.10.0
dbus-python==1.2.16
decorator==4.4.2
defusedxml==0.7.1
distro==1.4.0
dnspython==1.16.0
entrypoints==0.3
gTTS==2.2.3
httplib2==0.14.0
idna==2.8
imageio==2.4.1
importlib-metadata==1.5.0
ipykernel==5.5.5
ipython==7.24.0
ipython-genutils==0.2.0
ipywidgets==7.6.3
jedi==0.18.0
Jinja2==3.0.1
json5==0.9.5
jsonschema==3.2.0
jupyter==1.0.0
jupyter-client==6.1.12
jupyter-console==6.4.0
jupyter-core==4.7.1
jupyter-server==1.8.0
jupyterlab==3.0.16
jupyterlab-pygments==0.1.2
jupyterlab-server==2.5.2
jupyterlab-widgets==1.0.0
jupyterplot==0.0.3
keyring==18.0.1
kiwisolver==1.0.1
launchpadlib==1.10.13
lazr.restfulclient==0.14.2
lazr.uri==1.0.3
lrcurve==1.1.0
lxml==4.5.0
MarkupSafe==2.0.1
matplotlib==3.1.2
matplotlib-inline==0.1.2
mistune==0.8.4
more-itertools==4.2.0
mpmath==1.1.0
nbclassic==0.3.1
nbclient==0.5.3
nbconvert==6.0.7
nbformat==5.1.3
nest-asyncio==1.5.1
netifaces==0.11.0
networkx==2.4
notebook==6.4.0
numexpr==2.7.1
numpy==1.20.3
oauthlib==3.1.0
packaging==20.3
pandas==0.25.3
pandocfilters==1.4.3
parso==0.8.2
pbr==5.6.0
pexpect==4.8.0
pickleshare==0.7.5
Pillow==7.0.0
pkg-resources==0.0.0
plotly==5.1.0
pluggy==0.13.0
ply==3.11
prometheus-client==0.10.1
prompt-toolkit==3.0.18
ptyprocess==0.7.0
py==1.8.1
PyAudio==0.2.11
pycairo==1.20.1
pycparser==2.19
pycrypto==2.6.1
pycurl==7.43.0.2
Pygments==2.9.0
PyGObject==3.36.0
pygraphviz==1.5
PyJWT==1.7.1
pymacaroons==0.13.0
PyNaCl==1.3.0
pyparsing==2.4.6
pyrsistent==0.17.3
pytest==4.6.9
pytest-sourceorder==0.5.1
python-dateutil==2.7.3
pytz==2019.3
PyWavelets==0.5.1
PyYAML==5.3.1
pyzmq==22.1.0
qtconsole==5.1.0
QtPy==1.9.0
requests==2.22.0
requests-unixsocket==0.2.0
retrying==1.3.3
RISE==5.7.1
scikit-image==0.16.2
scipy==1.3.3
SecretStorage==2.3.1
Send2Trash==1.5.0
simplejson==3.16.0
six==1.14.0
sniffio==1.2.0
SpeechRecognition==3.8.1
SQLAlchemy==1.3.12
ssh-import-id==5.10
sympy==1.5.1
tenacity==8.0.0
terminado==0.10.0
testpath==0.5.0
testresources==2.0.1
tornado==6.1
traitlets==5.0.5
transitions==0.7.2
ubuntu-advantage-tools==20.3
unattended-upgrades==0.1
urllib3==1.25.8
uvloop==0.14.0
voila==0.2.10
voila-gridstack==0.2.0
wadllib==1.3.3
wcwidth==0.1.8
webencodings==0.5.1
websocket-client==1.0.1
widgetsnbextension==3.5.1
zipp==1.0.0
EOT

export PYNQ_VENV=/usr/local/share/pynq-venv

python3 -m venv --system-site-packages $PYNQ_VENV
source $PYNQ_VENV/bin/activate

python3 -m pip install pip==21.2.1
python3 -m pip install -r requirements.txt
rm requirements.txt
