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

do_compile_prepend_zynq () {
    PYNQ_BOARDNAME="${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARDNAME', True)}"
    echo "/include/ \"pynq_zynq.dtsi\"" >> ${DTS_FILES_PATH}/system-top.dts
    if [ -n "${PYNQ_BOARDNAME}" ]; then
        echo "/ { chosen { pynq_board = \"${PYNQ_BOARDNAME}\"; }; };" >> ${DTS_FILES_PATH}/system-top.dts
    else
        echo "No board set"
        exit 1
    fi
}
do_compile_prepend_zynqmp () {
    PYNQ_BOARDNAME="${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARDNAME', True)}"
    echo "/include/ \"pynq_zynqmp.dtsi\"" >> ${DTS_FILES_PATH}/system-top.dts
    if [ -n "${PYNQ_BOARDNAME}" ]; then
        echo "/ { chosen { pynq_board = \"${PYNQ_BOARDNAME}\"; }; };" >> ${DTS_FILES_PATH}/system-top.dts
    else
        echo "No board set"
        exit 1
    fi
}

do_compile[vardepsexclude] = "BB_ORIGENV"
