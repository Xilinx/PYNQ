source /etc/profile.d/pynq_venv.sh
source /etc/profile.d/xrt_setup.sh

mkdir -p /sys/class/fpga_manager/fpga0/firmware
mkdir -p /sys/class/fpga_manager/fpga0/state

python -c "from pynq import Overlay; ol = Overlay('base.bit', download=False, gen_cache=True)"

rm -rf /sys
