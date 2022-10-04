set -e
set -x

# remove unnecessary firmware to save space for zynq7000 boards
cd /lib/firmware
sudo rm -rf netronome mellanox mrvl qcom intel liquidio
