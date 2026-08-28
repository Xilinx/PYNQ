#!/usr/bin/env bash
#
# Build boot artefacts (BOOT.BIN, Image, system.dtb, modules.tgz, zocl.ko)
# for a PYNQ board with AMD's EDF/bitbake flow.
#
# Env inputs (set by the Makefile): BOARD, BOARD_PATH, ARCH, OUTPUT_DIR,
# ROOTDIR, FPGA_MANAGER, optional VIVADO_PATH. Per-board config is read from
# $BOARD_PATH/edf.env.

set -euo pipefail

BOARD="${BOARD:?BOARD must be set}"
BOARD_PATH="${BOARD_PATH:?BOARD_PATH must be set}"
OUTPUT_DIR="${OUTPUT_DIR:?OUTPUT_DIR must be set}"
ROOTDIR="${ROOTDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Exported so bitbake's BB_ORIGENV captures them (device-tree.bbappend reads
# these; BB_ENV_PASSTHROUGH_ADDITIONS whitelists them).
export PYNQ_BOARDNAME="${BOARD}"
export FPGA_MANAGER="${FPGA_MANAGER:-1}"
export PYNQ_BOARD_DTSI="${BOARD_PATH}/edf_bsp/board.dtsi"
# Optional per-board kernel config fragment, consumed by linux-xlnx.bbappend.
export PYNQ_BOARD_KCFG="${BOARD_PATH}/edf_bsp/kernel.cfg"
# Optional per-board u-boot overlay dir (patches + .cfg fragments), consumed by
# u-boot-xlnx.bbappend.
export PYNQ_BOARD_UBOOT_DIR="${BOARD_PATH}/edf_bsp/u-boot"

if [ -f "${BOARD_PATH}/edf.env" ]; then
    # shellcheck source=/dev/null
    source "${BOARD_PATH}/edf.env"
else
    echo "ERROR: ${BOARD_PATH}/edf.env not found. Board ${BOARD} is not configured for EDF." >&2
    exit 1
fi

EDF_MODE="${EDF_MODE:-prebuilt}"
EDF_MANIFEST_URL="${EDF_MANIFEST_URL:-https://github.com/Xilinx/yocto-manifests.git}"
EDF_MANIFEST_TAG="${EDF_MANIFEST_TAG:-amd-edf-rel-v25.11.1}"
EDF_MANIFEST_FILE="${EDF_MANIFEST_FILE:-default-edf.xml}"

EDF_BOOT_MACHINE="${EDF_BOOT_MACHINE:?Set EDF_BOOT_MACHINE in ${BOARD_PATH}/edf.env}"
EDF_LINUX_MACHINE="${EDF_LINUX_MACHINE:-${EDF_BOOT_MACHINE}}"
EDF_BOARD_DTS="${EDF_BOARD_DTS:-}"

EDF_CACHE="${EDF_CACHE:-${ROOTDIR}/edf-cache}"
EDF_DIR="${EDF_DIR:-${EDF_CACHE}/pynq-edf}"
SSTATE_DIR="${SSTATE_DIR:-${EDF_CACHE}/sstate}"
DL_DIR="${DL_DIR:-${EDF_CACHE}/downloads}"
META_PYNQ="${META_PYNQ:-${ROOTDIR}/boot/meta-pynq}"
BB_NUMBER_THREADS="${BB_NUMBER_THREADS:-$(nproc)}"
PARALLEL_MAKE_JOBS="${PARALLEL_MAKE_JOBS:-$(nproc)}"

# Source Vivado settings (needed for custom-mode SDT builds).
if [ -n "${VIVADO_PATH:-}" ]; then
    for candidate in "${VIVADO_PATH}/settings64.sh" "${VIVADO_PATH}/Vivado/settings64.sh"; do
        if [ -f "${candidate}" ]; then
            set +u; source "${candidate}"; set -u
            break
        fi
    done
fi

echo "============================================"
echo "PYNQ EDF boot artefact build"
echo "  Board:          ${BOARD}"
echo "  Mode:           ${EDF_MODE}"
echo "  EDF manifest:   ${EDF_MANIFEST_TAG}"
echo "  Boot machine:   ${EDF_BOOT_MACHINE}"
echo "  Linux machine:  ${EDF_LINUX_MACHINE}"
echo "  EDF directory:  ${EDF_DIR}"
echo "  Output:         ${OUTPUT_DIR}/${BOARD}"
echo "============================================"

# Step 1: repo init + sync the EDF manifest.
step_init_edf() {
    echo ""; echo "--- Step 1: Initialise EDF ---"
    mkdir -p "${EDF_DIR}"
    cd "${EDF_DIR}"
    if [ ! -d ".repo" ]; then
        repo init -q -u "${EDF_MANIFEST_URL}" -b "refs/tags/${EDF_MANIFEST_TAG}" \
            -m "${EDF_MANIFEST_FILE}" --depth=1 </dev/null
        if [ ! -d ".repo" ]; then
            echo "ERROR: repo init did not create ${EDF_DIR}/.repo." >&2
            echo "       Remove any stray .repo directory in a parent of EDF_DIR." >&2
            exit 1
        fi
    fi
    local sync_jobs; sync_jobs=$(nproc)
    if [ "${sync_jobs}" -gt 8 ]; then sync_jobs=8; fi
    repo sync -q -j"${sync_jobs}" --force-sync
}

# Step 2: source the EDF build env, configure caches, add the meta-pynq layer.
step_setup_build_env() {
    echo ""; echo "--- Step 2: Set up Yocto build environment ---"
    cd "${EDF_DIR}"
    set +u
    # shellcheck source=/dev/null
    source edf-init-build-env
    set -u

    local localconf="${BUILDDIR:-${EDF_DIR}/build}/conf/local.conf"
    if ! grep -q "PYNQ_CONF_APPLIED" "${localconf}" 2>/dev/null; then
        cat >> "${localconf}" <<EOF

# --- PYNQ build configuration (PYNQ_CONF_APPLIED) ---
SSTATE_DIR = "${SSTATE_DIR}"
DL_DIR = "${DL_DIR}"
BB_NUMBER_THREADS = "${BB_NUMBER_THREADS}"
PARALLEL_MAKE = "-j ${PARALLEL_MAKE_JOBS}"
INHERIT += "rm_work"

# Mask meta-pynq recipes not yet ported to Scarthgap.
BBMASK += "meta-pynq/recipes-filesystem/python/python3-pynq.*\.bb"
BBMASK += "meta-pynq/recipes-core/images/petalinux-image-full\.bbappend"
EOF
    fi

    if [ -d "${META_PYNQ}" ]; then
        if bitbake-layers show-layers 2>/dev/null | grep -q "${META_PYNQ}"; then
            echo "  meta-pynq already in bblayers"
        else
            bitbake-layers add-layer "${META_PYNQ}"
        fi
    else
        echo "  WARN: meta-pynq layer not found at ${META_PYNQ}"
    fi
}

# Step 3 (custom mode only): generate a Yocto machine from a board XSA.
step_setup_custom_bsp() {
    [ "${EDF_MODE}" = "prebuilt" ] && return
    echo ""; echo "--- Step 3: Custom BSP setup ---"

    local xsa=""
    if [ -n "${BSP_XSA_PATH:-}" ] && [ -f "${BOARD_PATH}/${BSP_XSA_PATH}" ]; then
        xsa="${BOARD_PATH}/${BSP_XSA_PATH}"
    else
        for c in "${BOARD_PATH}/base/base.xsa" "${BOARD_PATH}/overlays/base/base.xsa"; do
            [ -f "${c}" ] && { xsa="${c}"; break; }
        done
    fi
    [ -n "${xsa}" ] || { echo "ERROR: no XSA for custom mode (set BSP_XSA_PATH or place base/base.xsa)." >&2; exit 1; }

    # Regenerate the SDT and the generated machine layer from scratch every build
    local sdt_dir="${BUILDDIR:-${EDF_DIR}/build}/hw_project_sdt"
    rm -rf "${sdt_dir}"
    mkdir -p "${sdt_dir}"
    # board_dts is optional: when unset the generic SoC SDT is used and all
    # board-specific nodes come from edf_bsp/board.dtsi.
    local board_dts_line=""
    [ -n "${EDF_BOARD_DTS}" ] && board_dts_line="set_dt_param -board_dts ${EDF_BOARD_DTS}"
    if command -v sdtgen &>/dev/null; then
        sdtgen <<SDTEOF
set_dt_param -dir ${sdt_dir}
set_dt_param -xsa ${xsa}
${board_dts_line}
generate_sdt
exit
SDTEOF
    else
        echo "ERROR: sdtgen not on PATH. Source Vivado settings64.sh (set VIVADO_PATH)." >&2
        exit 1
    fi

    local custom_layer="${EDF_DIR}/sources/meta-pynq-machine"
    cd "${BUILDDIR:-${EDF_DIR}/build}"
    bitbake-layers remove-layer "${custom_layer}" 2>/dev/null || true
    rm -rf "${custom_layer}"
    bitbake-layers create-layer "${custom_layer}"
    bitbake-layers add-layer "${custom_layer}"
    gen-machine-conf parse-sdt --hw-description "${sdt_dir}" \
        -c "${custom_layer}/conf" -g full --machine-name "${EDF_BOOT_MACHINE}"

    # Trim the SDT's architectural-max high DDR bank to the board's real size via a
    # label override (dtc last-value-wins); u-boot and the kernel share this dts.
    if [ -n "${EDF_DDR_HIGH_BANK_REG:-}" ]; then
        echo "  Trimming high DDR bank (memory@800000000) to: ${EDF_DDR_HIGH_BANK_REG}"
        local dts
        for dts in "${custom_layer}/conf/dts/${EDF_BOOT_MACHINE}"/*.dts; do
            [ -f "${dts}" ] || continue
            grep -q "psu_ddr_1_memory:" "${dts}" || continue
            printf '\n&psu_ddr_1_memory { reg = <%s>; };\n' "${EDF_DDR_HIGH_BANK_REG}" >> "${dts}"
        done
    fi
}

# Step 4-5: bitbake boot artefacts, kernel, zocl.
step_build() {
    cd "${BUILDDIR:-${EDF_DIR}/build}"
    # Rebuild the PYNQ-affected boot recipes so source edits apply (sstate can
    # otherwise reuse stale outputs). EDF_NO_CLEAN=1 skips.
    if [ "${EDF_NO_CLEAN:-0}" != "1" ]; then
        echo ""; echo "--- cleansstate device-tree / u-boot / bootbin ---"
        MACHINE="${EDF_BOOT_MACHINE}" bitbake -c cleansstate \
            device-tree u-boot-xlnx xilinx-bootbin || true
    fi
    echo ""; echo "--- Step 4: bitbake xilinx-bootbin ---"
    MACHINE="${EDF_BOOT_MACHINE}" bitbake xilinx-bootbin
    echo ""; echo "--- Step 5: bitbake virtual/kernel ---"
    MACHINE="${EDF_BOOT_MACHINE}" bitbake virtual/kernel
    echo ""; echo "--- Step 5b: bitbake zocl (XRT kernel module) ---"
    MACHINE="${EDF_BOOT_MACHINE}" bitbake zocl
    echo ""; echo "--- Step 5c: bitbake kernel-devsrc (on-target build tree) ---"
    MACHINE="${EDF_BOOT_MACHINE}" bitbake kernel-devsrc
}

# Step 6: copy artefacts into $OUTPUT_DIR/<board>/.
step_extract_artifacts() {
    echo ""; echo "--- Step 6: Extract artefacts ---"
    local deploy="${BUILDDIR:-${EDF_DIR}/build}/tmp/deploy/images/${EDF_BOOT_MACHINE}"
    local linux_deploy="${BUILDDIR:-${EDF_DIR}/build}/tmp/deploy/images/${EDF_LINUX_MACHINE}"
    local board_out="${OUTPUT_DIR}/${BOARD}"
    mkdir -p "${board_out}"

    # BOOT.BIN
    if [ -f "${deploy}/boot.bin" ]; then cp "${deploy}/boot.bin" "${board_out}/BOOT.BIN"
    elif [ -f "${deploy}/BOOT.BIN" ]; then cp "${deploy}/BOOT.BIN" "${board_out}/BOOT.BIN"
    else echo "ERROR: BOOT.BIN not found in ${deploy}" >&2; ls -la "${deploy}/" 2>/dev/null || true; exit 1; fi

    # Kernel Image (may be in a sibling deploy dir when boot != linux machine)
    local image_found=false
    for d in "${deploy}" "${linux_deploy}"; do
        if [ -f "${d}/Image" ]; then cp "${d}/Image" "${board_out}/Image"; image_found=true; break; fi
    done
    [ "${image_found}" = true ] || { echo "ERROR: kernel Image not found in ${deploy} or ${linux_deploy}" >&2; exit 1; }

    # Device tree (first non-symlink .dtb)
    for dtb in "${deploy}/system.dtb" "${deploy}/"*.dtb; do
        if [ -f "${dtb}" ] && [ ! -L "${dtb}" ]; then cp "${dtb}" "${board_out}/system.dtb"; break; fi
    done

    # Kernel modules tarball
    for mt in "${linux_deploy}/modules-"*.tgz "${deploy}/modules-"*.tgz; do
        if [ -f "${mt}" ]; then cp "${mt}" "${board_out}/modules.tgz"; break; fi
    done

    # zocl.ko: extract from the RPM (do_rm_work removes the build WORKDIR).
    local zocl_rpm
    zocl_rpm=$(find "${BUILDDIR:-${EDF_DIR}/build}/tmp/deploy/rpm" -name 'kernel-module-zocl*.rpm' \
        -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2-)
    if [ -n "${zocl_rpm}" ] && [ -f "${zocl_rpm}" ]; then
        local tmp; tmp=$(mktemp -d)
        ( cd "${tmp}" && rpm2cpio "${zocl_rpm}" | cpio -idm 2>/dev/null )
        local ko; ko=$(find "${tmp}" -name 'zocl.ko' | head -n1)
        if [ -n "${ko}" ]; then cp "${ko}" "${board_out}/zocl.ko"; echo "  zocl.ko from $(basename "${zocl_rpm}")"; \
        else echo "  WARN: zocl.ko not inside ${zocl_rpm}" >&2; fi
        rm -rf "${tmp}"
    else
        echo "  WARN: kernel-module-zocl RPM not found (XRT will be unable to use the device)" >&2
    fi

    # kernel-devsrc RPM: on-target build tree (/usr/src/kernel +
    # /lib/modules/<kver>/build) for compiling kernel modules on the board.
    local devsrc_rpm
    devsrc_rpm=$(find "${BUILDDIR:-${EDF_DIR}/build}/tmp/deploy/rpm" -name 'kernel-devsrc*.rpm' \
        -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2-)
    if [ -n "${devsrc_rpm}" ] && [ -f "${devsrc_rpm}" ]; then
        cp "${devsrc_rpm}" "${board_out}/kernel-devsrc.rpm"
        echo "  kernel-devsrc.rpm from $(basename "${devsrc_rpm}")"
    else
        echo "  WARN: kernel-devsrc RPM not found (on-target module builds unavailable)" >&2
    fi

    echo ""; echo "Artefacts:"; ls -lh "${board_out}/"
}

# Versal SD autoboot glue: boot.scr + uEnv.txt + uboot.env + extlinux.conf.
# Versal's U-Boot drops to the EFI boot menu unless an environment whose
# bootcmd loads the kernel from SD is supplied. uboot.env must use the
# redundant layout (mkenvimage -r) at the 128 KB size Versal's
# CONFIG_ENV_SIZE expects, or U-Boot misparses it and ignores bootcmd.
_write_versal_boot_config() {
    local board_out="$1"
    local serial_tty="ttyAMA0" env_size=131072
    local bootargs="earlycon console=${serial_tty},115200 clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait uio_pdrv_genirq.of_id=generic-uio"
    local bootcmd="load mmc 0:1 0x10000000 Image; load mmc 0:1 0x20000000 system.dtb; setenv bootargs ${bootargs}; booti 0x10000000 - 0x20000000"

    local cmd; cmd=$(mktemp)
    {
        echo "setenv bootargs '${bootargs}'"
        echo "load mmc 0:1 0x10000000 Image"
        echo "load mmc 0:1 0x20000000 system.dtb"
        echo "booti 0x10000000 - 0x20000000"
    } > "${cmd}"
    mkimage -A arm64 -O linux -T script -C none -n "PYNQ ${BOARD} boot" \
        -d "${cmd}" "${board_out}/boot.scr"
    cp "${board_out}/boot.scr" "${board_out}/boot.scr.uimg"
    rm -f "${cmd}"

    cat > "${board_out}/uEnv.txt" <<EOF
bootcmd=${bootcmd}
uenvcmd=run bootcmd
EOF

    local env_txt; env_txt=$(mktemp)
    cat > "${env_txt}" <<EOF
bootcmd=${bootcmd}
bootdelay=3
EOF
    mkenvimage -r -s "${env_size}" -o "${board_out}/uboot.env" "${env_txt}"
    rm -f "${env_txt}"

    {
        echo "default pynq"
        echo "timeout 3"
        echo "label pynq"
        echo "    menu label PYNQ ${BOARD}"
        echo "    kernel /Image"
        echo "    fdt /system.dtb"
        echo "    append ${bootargs}"
    } > "${board_out}/extlinux/extlinux.conf"
    echo "  wrote Versal autoboot glue (boot.scr, uEnv.txt, uboot.env, extlinux.conf)"
}

# Step 7: boot-partition config.
step_write_boot_config() {
    echo ""; echo "--- Step 7: Boot config ---"
    local board_out="${OUTPUT_DIR}/${BOARD}"
    install -d "${board_out}/extlinux"

    case "${EDF_BOOT_MACHINE}" in
        *versal*)
            _write_versal_boot_config "${board_out}"
            ;;
        *)
            # No 'append': bootargs are authoritative in the DT (/chosen/bootargs).
            {
                echo "default pynq"
                echo "timeout 3"
                echo "label pynq"
                echo "    menu label PYNQ ${BOARD}"
                echo "    kernel /Image"
                echo "    fdt /system.dtb"
            } > "${board_out}/extlinux/extlinux.conf"
            echo "  wrote extlinux/extlinux.conf"
            ;;
    esac
}

main() {
    step_init_edf
    step_setup_build_env
    step_setup_custom_bsp
    step_build
    step_extract_artifacts
    step_write_boot_config
    echo ""; echo "============================================"
    echo "EDF boot artefact build complete: ${OUTPUT_DIR}/${BOARD}"
    echo "============================================"
}

main "$@"
