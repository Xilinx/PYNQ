set -x
set -e

# SSL fix needed for armhf certificates...
# https://github.com/RPi-Distro/pi-gen/issues/271
c_rehash /etc/ssl/certs
