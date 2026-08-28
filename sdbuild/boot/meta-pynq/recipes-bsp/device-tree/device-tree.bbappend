FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

FPGA_MANAGER := "${@d.getVar('BB_ORIGENV', False).getVar('FPGA_MANAGER', True) or '1'}"

# Track board.dtsi's content hash so edits invalidate the device-tree sstate.
PYNQ_BOARD_DTSI := "${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARD_DTSI', True) or ''}"
do_configure[file-checksums] += "${@(d.getVar('PYNQ_BOARD_DTSI') + ':True') if d.getVar('PYNQ_BOARD_DTSI') else ''}"

# Only the Linux device tree gets these; the Versal PMC and PSM MicroBlaze
# device trees have no gic or /axi to reference.
PYNQ_DT_FRAGMENTS ?= ""
PYNQ_DT_FRAGMENTS:zynqmp = "pynq_xlnk_zynqmp.dtsi pynq_uio_zynqmp.dtsi ${@'pynq_zocl_poll_zynqmp.dtsi' if d.getVar('FPGA_MANAGER') == '1' else 'pynq_zocl_intc_zynqmp.dtsi'}"
PYNQ_DT_FRAGMENTS:versal = "pynq_uio_versal.dtsi pynq_zocl_poll_versal.dtsi"

EXTRA_DT_INCLUDE_FILES:append:linux = " pynq_bootargs.dtsi ${PYNQ_DT_FRAGMENTS}"

do_configure:append:linux() {
    dts="${DT_FILES_PATH}/${BASE_DTS}.dts"
    board_dtsi="${PYNQ_BOARD_DTSI}"
    board_name="${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARDNAME', True) or 'Unknown'}"
    if [ -n "${board_dtsi}" ] && [ -f "${board_dtsi}" ]; then
        printf '\n' >> "${dts}"
        cat "${board_dtsi}" >> "${dts}"
    fi
    printf '\n/ { chosen { pynq_board = "%s"; }; };\n' "${board_name}" >> "${dts}"
}

do_configure[vardepsexclude] = "BB_ORIGENV"
