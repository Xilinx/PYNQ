SUMMARY = "PYNQ.remote on-target self-test"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SELFTEST_PKG = "${@os.path.dirname(d.getVar('FILE'))}/../../../../packages/selftest"
FILESEXTRAPATHS:prepend := "${SELFTEST_PKG}/tests/bash/remote:${SELFTEST_PKG}/tests/bash:${SELFTEST_PKG}/lib:${SELFTEST_PKG}:"

SRC_URI = " \
    file://pynq-remote-selftest \
    file://results.sh \
    file://mac.sh \
    file://pynq_remote_service.sh \
    file://grpc_listen.sh \
    file://xrt_zocl.sh \
    file://fpga_manager.sh \
    file://board_identity.sh \
"

S = "${WORKDIR}"
REMOTE_ROOT = "${D}/usr/local/share/pynq-remote-selftest"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/pynq-remote-selftest ${D}${bindir}/pynq-remote-selftest

    install -d ${REMOTE_ROOT}/lib
    install -d ${REMOTE_ROOT}/tests/remote
    install -m 0644 ${WORKDIR}/results.sh ${REMOTE_ROOT}/lib/results.sh
    install -m 0644 ${WORKDIR}/pynq_remote_service.sh ${REMOTE_ROOT}/tests/remote/pynq_remote_service.sh
    install -m 0644 ${WORKDIR}/grpc_listen.sh ${REMOTE_ROOT}/tests/remote/grpc_listen.sh
    install -m 0644 ${WORKDIR}/xrt_zocl.sh ${REMOTE_ROOT}/tests/remote/xrt_zocl.sh
    install -m 0644 ${WORKDIR}/fpga_manager.sh ${REMOTE_ROOT}/tests/remote/fpga_manager.sh
    install -m 0644 ${WORKDIR}/mac.sh ${REMOTE_ROOT}/tests/remote/mac.sh
    install -m 0644 ${WORKDIR}/board_identity.sh ${REMOTE_ROOT}/tests/remote/board_identity.sh
}

RDEPENDS:${PN} += "bash"

FILES:${PN} += " \
    ${bindir}/pynq-remote-selftest \
    /usr/local/share/pynq-remote-selftest/lib/results.sh \
    /usr/local/share/pynq-remote-selftest/tests/remote/pynq_remote_service.sh \
    /usr/local/share/pynq-remote-selftest/tests/remote/grpc_listen.sh \
    /usr/local/share/pynq-remote-selftest/tests/remote/xrt_zocl.sh \
    /usr/local/share/pynq-remote-selftest/tests/remote/fpga_manager.sh \
    /usr/local/share/pynq-remote-selftest/tests/remote/mac.sh \
    /usr/local/share/pynq-remote-selftest/tests/remote/board_identity.sh \
"
