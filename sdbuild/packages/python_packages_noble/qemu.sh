export HOME=/root

set -x
set -e

cd /root

export PYNQ_VENV=/usr/local/share/pynq-venv

# --system-site-packages lets the venv see apt-installed python3 modules
# (numpy etc.) instead of recompiling them from source under qemu.
python3 -m venv --system-site-packages --upgrade-deps ${PYNQ_VENV}
echo "source ${PYNQ_VENV}/bin/activate" > /etc/profile.d/pynq_venv.sh
source /etc/profile.d/pynq_venv.sh

# pip/setuptools float to whatever noble ships; the jammy pins (pip==22.0.2,
# setuptools==59.6.0) don't install on Python 3.12.
python3 -m pip install --upgrade wheel

python3 -m pip install -r requirements.txt
rm requirements.txt
