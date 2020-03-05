FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append = "\
    file://pynq_xlnk.dtsi \
    file://pynq_xlnk_zynqmp.dtsi \
    file://pynq_uio.dtsi \
    file://pynq_uio_zynqmp.dtsi \
    file://pynq_bootargs.dtsi \
    file://pynq_zynq.dtsi \
    file://pynq_zynqmp.dtsi \
"

# PYNQ_BOARDNAME="${BB_ORIGENV[PYNQ_BOARDNAME]}"

do_configure_append_zynq () {
    PYNQ_BOARDNAME="${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARDNAME', True)}"
    echo '/include/ "pynq_zynq.dtsi"' >> ${DT_FILES_PATH}/system-top.dts
    if [ -n "${PYNQ_BOARDNAME}" ]; then
        echo "/ { chosen { pynq_board = \"${PYNQ_BOARDNAME}\"; }; };" >> ${DT_FILES_PATH}/system-top.dts
    else
        echo "No board set"
        exit 1
    fi
}
do_configure_append_zynqmp () {
    PYNQ_BOARDNAME="${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARDNAME', True)}"
    echo '/include/ "pynq_zynqmp.dtsi"' >> ${DT_FILES_PATH}/system-top.dts
    if [ -n "${PYNQ_BOARDNAME}" ]; then
        echo "/ { chosen { pynq_board = \"${PYNQ_BOARDNAME}\"; }; };" >> ${DT_FILES_PATH}/system-top.dts
    else
        echo "No board set"
        exit 1
    fi
}

do_configure[vardepsexclude] = "BB_ORIGENV"
