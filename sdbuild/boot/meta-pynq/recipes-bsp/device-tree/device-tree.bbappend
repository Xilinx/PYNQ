FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append = "\
    file://pynq_xlnk_zynq.dtsi \
    file://pynq_xlnk_zynqmp.dtsi \
    file://pynq_zocl_poll_zynq.dtsi \
    file://pynq_zocl_poll_zynqmp.dtsi \
    file://pynq_zocl_intc_zynq.dtsi \
    file://pynq_zocl_intc_zynqmp.dtsi \
    file://pynq_uio_zynq.dtsi \
    file://pynq_uio_zynqmp.dtsi \
    file://pynq_bootargs.dtsi \
    file://pynq_zynq.dtsi \
    file://pynq_zynqmp.dtsi \
"

# PYNQ_BOARDNAME="${BB_ORIGENV[PYNQ_BOARDNAME]}"
# FPGA_MANAGER="${BB_ORIGENV[FPGA_MANAGER]}"

do_configure_append_zynq () {
    PYNQ_BOARDNAME="${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARDNAME', True)}"
    FPGA_MANAGER="${@d.getVar('BB_ORIGENV', False).getVar('FPGA_MANAGER', True)}"
    echo '/include/ "pynq_zynq.dtsi"' >> ${DT_FILES_PATH}/system-top.dts
    if [ "${FPGA_MANAGER}" = 1 ]; then
        echo "/include/ \"pynq_uio_zynq.dtsi\"" >> ${DT_FILES_PATH}/system-top.dts
        echo "/include/ \"pynq_zocl_poll_zynq.dtsi\"" >> ${DT_FILES_PATH}/system-top.dts
    else
        echo "/include/ \"pynq_zocl_intc_zynq.dtsi\"" >> ${DT_FILES_PATH}/system-top.dts
    fi
    if [ -n "${PYNQ_BOARDNAME}" ]; then
        echo "/ { chosen { pynq_board = \"${PYNQ_BOARDNAME}\"; }; };" >> ${DT_FILES_PATH}/system-top.dts
    else
        echo "No board set"
        exit 1
    fi
}
do_configure_append_zynqmp () {
    PYNQ_BOARDNAME="${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARDNAME', True)}"
	FPGA_MANAGER="${@d.getVar('BB_ORIGENV', False).getVar('FPGA_MANAGER', True)}"
    echo '/include/ "pynq_zynqmp.dtsi"' >> ${DT_FILES_PATH}/system-top.dts
    if [ "${FPGA_MANAGER}" = 1 ]; then
        echo "/include/ \"pynq_uio_zynqmp.dtsi\"" >> ${DT_FILES_PATH}/system-top.dts
        echo "/include/ \"pynq_zocl_poll_zynqmp.dtsi\"" >> ${DT_FILES_PATH}/system-top.dts
    else
        echo "/include/ \"pynq_zocl_intc_zynqmp.dtsi\"" >> ${DT_FILES_PATH}/system-top.dts
    fi
    if [ -n "${PYNQ_BOARDNAME}" ]; then
        echo "/ { chosen { pynq_board = \"${PYNQ_BOARDNAME}\"; }; };" >> ${DT_FILES_PATH}/system-top.dts
    else
        echo "No board set"
        exit 1
    fi
}

do_configure[vardepsexclude] = "BB_ORIGENV"
