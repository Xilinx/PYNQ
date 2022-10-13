export HOME=/root

set -x
set -e


# Captured using pip3 freeze on image after packages installed with no versions
cd /root

export PYNQ_VENV=/usr/local/share/pynq-venv

python3 -m venv --system-site-packages $PYNQ_VENV
echo "source $PYNQ_VENV/bin/activate" > /etc/profile.d/pynq_venv.sh
source /etc/profile.d/pynq_venv.sh

python3 -m pip install pip==22.0.2
python3 -m pip install -r requirements.txt
rm requirements.txt
