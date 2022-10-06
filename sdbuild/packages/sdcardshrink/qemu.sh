set -e
set -x

# remove unnecessary firmware to save space for zynq7000 boards
cd /lib/firmware
rm -rf netronome mellanox mrvl qcom intel liquidio amdgpu i915 dpaa2
