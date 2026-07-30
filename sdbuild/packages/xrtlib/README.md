# xrtlib — XRT + pyxrt for PYNQ

Builds the Xilinx Runtime (XRT) userspace libraries and the `pyxrt`
Python bindings from source and installs them into the PYNQ image.

`qemu.sh` runs inside the sdbuild container's aarch64 chroot and:

- clones XRT at tag `202520.2.20.197` (Xilinx 2025.2 / XRT 2.20),
- builds the embedded (`-edge`) variant for the zocl/DRM device path,
- installs `libxrt_*` under `/opt/xilinx/xrt/` and registers it with
  `ldconfig`,
- stages `pyxrt` into the PYNQ venv (`/usr/local/share/pynq-venv`).

The XRT tag is kept in sync with the `zocl` kernel-module recipe
(`sdbuild/boot/meta-pynq/recipes-xrt/zocl/`) so the userspace and
kernel-side ABIs match. Build dependencies come from the base rootfs
manifest (`sdbuild/ubuntu/noble/aarch64/multistrap.config`).
