#!/bin/bash
#
# Build XRT userspace + pyxrt (Python pybind11 bindings) inside the
# qemu-emulated chroot, then stage pyxrt into the PYNQ venv.

set -e
set -x

ARCH=$(uname -m)
if [[ "${ARCH}" != "aarch64" ]]; then
    echo "ERROR: xrtlib only supports aarch64 (got ${ARCH})." >&2
    exit 1
fi

# Pin XRT to the same tag as the zocl kernel module recipe in
# sdbuild/boot/meta-pynq/recipes-xrt/zocl/zocl_git.bb. Userspace and
# kernel-side ABIs need to match.
XRT_TAG="202520.2.20.197"

# pyxrt is installed into the PYNQ venv, so it must already exist
# (python_packages_noble creates it in STAGE2).
PYNQ_VENV="/usr/local/share/pynq-venv"
if [ ! -d "${PYNQ_VENV}" ]; then
    echo "ERROR: ${PYNQ_VENV} missing; run python_packages_noble first." >&2
    exit 1
fi

# shellcheck disable=SC1091
. "${PYNQ_VENV}/bin/activate"

PYTHON_BIN="${PYNQ_VENV}/bin/python3"
if [ ! -x "${PYTHON_BIN}" ]; then
    PYTHON_BIN="$(command -v python3)"
fi

PY_VERSION_SHORT="$(${PYTHON_BIN} -c 'import sys; print("%d.%d"%sys.version_info[:2])')"
PY_SITE_PACKAGES="$(${PYTHON_BIN} -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"

echo "--- xrtlib build ---"
echo "  XRT tag:          ${XRT_TAG}"
echo "  Python:           ${PYTHON_BIN}  (${PY_VERSION_SHORT})"
echo "  pyxrt install to: ${PY_SITE_PACKAGES}/pyxrt.so"

# A stray PKG_CONFIG_LIBDIR would make pkg-config miss the chroot's
# system libraries and break cmake's package lookup.
unset PKG_CONFIG_LIBDIR

cd /root

git clone https://github.com/Xilinx/XRT xrt-git
cd xrt-git
git checkout "tags/${XRT_TAG}" -b temp
git submodule init
git submodule update

# Force pyxrt to be built in the embedded variant; embedded_system.cmake
# otherwise skips python/.
echo "" >> src/CMake/embedded_system.cmake
echo "set (XRT_INSTALL_PYTHON_DIR \"\${XRT_INSTALL_DIR}/python\")" >> src/CMake/embedded_system.cmake
echo "add_subdirectory(python)" >> src/CMake/embedded_system.cmake

# Skip the HW-emulation plugins: they need the x86-only xrt_hwemu target.
sed -i 's/^if (NOT WIN32)$/if (FALSE)/' \
    src/runtime_src/xdp/profile/plugin/pl_deadlock/CMakeLists.txt
sed -i 's|^add_subdirectory(device_offload/hw_emu)$|# skipped: no xrt_hwemu in embedded build|' \
    src/runtime_src/xdp/profile/plugin/CMakeLists.txt

# Stub {get,set}_aie_freq: ZynqMP has no AIE and XRT 2.20 misses the
# #ifdef XRT_ENABLE_AIE guard on these call sites (only on the decls).
sed -i 's|return m_shim->get_aie_freq(this);|throw xrt_core::error(std::errc::not_supported, __func__);|' \
    src/runtime_src/core/edge/user/hwctx_object.cpp
sed -i 's|return m_shim->set_aie_freq(this, freq_hz);|throw xrt_core::error(std::errc::not_supported, __func__);|' \
    src/runtime_src/core/edge/user/hwctx_object.cpp

cd build
# -edge builds the embedded (zocl) shim; see XRT-install-location.md.
XRT_NATIVE_BUILD=no ./build.sh -dbg -edge -noctest -noinit -noert
cd Debug
make install

PYXRT_SO="$(find /root/xrt-git/build -name 'pyxrt*.so' -print -quit)"
if [ -z "${PYXRT_SO}" ]; then
    echo "ERROR: pyxrt.so not produced by the XRT build." >&2
    find /root/xrt-git/build -name '*.so' | head -20 >&2
    exit 1
fi
echo "Found pyxrt artefact: ${PYXRT_SO}"

# Install the as-built name plus a plain pyxrt.so symlink so `import pyxrt`
# works regardless of the ABI tag.
install -m 0755 "${PYXRT_SO}" "${PY_SITE_PACKAGES}/$(basename "${PYXRT_SO}")"
ln -sf "$(basename "${PYXRT_SO}")" "${PY_SITE_PACKAGES}/pyxrt.so"

# pyxrt dlopens libxrt_*.so.2 from /opt/xilinx/xrt/lib; register it.
echo "/opt/xilinx/xrt/lib" > /etc/ld.so.conf.d/xrt.conf
ldconfig

# Install the XRT tool-wrapper loader and setup scripts.
install -d /opt/xilinx/xrt/bin/unwrapped
install -m 0755 /root/xrt-git/src/runtime_src/tools/scripts/loader \
    /opt/xilinx/xrt/bin/unwrapped/loader
install -m 0644 /root/xrt-git/src/runtime_src/tools/scripts/setup.sh \
    /opt/xilinx/xrt/setup.sh
install -m 0644 /root/xrt-git/src/runtime_src/tools/scripts/setup.csh \
    /opt/xilinx/xrt/setup.csh

${PYTHON_BIN} -c 'import pyxrt; print("pyxrt imported OK:", pyxrt.__file__)'

cd /
rm -rf /root/xrt-git
