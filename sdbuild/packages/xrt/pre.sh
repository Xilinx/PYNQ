#!/bin/bash

set -x
set -e

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo install -d "$target/etc/profile.d"
sudo cp -f "$script_dir/xrt_setup.sh" "$target/etc/profile.d/"

# zocl.ko comes from the EDF bitbake boot build (output/boot/<board>/), not
# petalinux-build. Install it into the rootfs module tree so modprobe finds it.
zocl_src="${BOOT_ROOT}/zocl.ko"
if [ ! -f "$zocl_src" ]; then
    echo "ERROR: $zocl_src not found (build_edf_boot.sh should produce it)." >&2
    exit 1
fi

kver="$(ls -1 "$target/lib/modules" 2>/dev/null | sort -V | tail -n1)"
if [ -z "$kver" ]; then
    echo "ERROR: no kernel modules dir in $target/lib/modules." >&2
    exit 1
fi

sudo install -d "$target/lib/modules/$kver/extra"
sudo install -m 0644 "$zocl_src" "$target/lib/modules/$kver/extra/zocl.ko"

# Auto-load zocl (XRT device) and uio_pdrv_genirq (binds the generic-uio
# fabric node so /dev/uio0 appears) at boot.
sudo install -d "$target/etc/modules-load.d"
echo zocl | sudo tee "$target/etc/modules-load.d/pynq-zocl.conf" >/dev/null
echo uio_pdrv_genirq | sudo tee "$target/etc/modules-load.d/pynq-uio.conf" >/dev/null
