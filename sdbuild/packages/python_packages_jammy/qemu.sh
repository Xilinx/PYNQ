export HOME=/root

set -x
set -e


# Captured using pip3 freeze on image after packages installed with no versions
cd /root

export PYNQ_VENV=/usr/local/share/pynq-venv

if [ ${ARCH} == 'arm' ]; then
    export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig
else
    export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
fi

python3 -m venv --system-site-packages --upgrade-deps $PYNQ_VENV
echo "source $PYNQ_VENV/bin/activate" > /etc/profile.d/pynq_venv.sh
source /etc/profile.d/pynq_venv.sh


# PYNQv3.1 fix - argon2-cffi-bindings dependency checker breaks
# installing outside of requirements.txt with newer setuptools, then
# revert back to setuptools==59.6.0
python3 -m pip install argon2-cffi-bindings==21.2.0

python3 -m pip install --upgrade setuptools==59.6.0
python3 -m pip install --upgrade pip==22.0.2
python3 -m pip install -r requirements.txt
rm requirements.txt
