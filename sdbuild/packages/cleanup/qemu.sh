set -e
set -x

# cleanup leftover jenkins home folder
cd /home
sudo rm -rf jenkins

# remove unnecessary firmware to save space for zynq7000 boards
cd /lib/firmware
sudo rm -rf netronome mellanox mrvl intel
