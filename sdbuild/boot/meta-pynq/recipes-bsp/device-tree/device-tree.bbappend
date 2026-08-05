FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

FPGA_MANAGER := "${@d.getVar('BB_ORIGENV', False).getVar('FPGA_MANAGER', True) or '1'}"

# Track board.dtsi's content hash so edits invalidate the device-tree sstate.
PYNQ_BOARD_DTSI := "${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARD_DTSI', True) or ''}"
do_configure[file-checksums] += "${@(d.getVar('PYNQ_BOARD_DTSI') + ':True') if d.getVar('PYNQ_BOARD_DTSI') else ''}"

EXTRA_DT_INCLUDE_FILES:append:linux = " pynq_xlnk_zynqmp.dtsi pynq_uio_zynqmp.dtsi pynq_bootargs.dtsi ${@'pynq_zocl_poll_zynqmp.dtsi' if d.getVar('FPGA_MANAGER') == '1' else 'pynq_zocl_intc_zynqmp.dtsi'}"

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
