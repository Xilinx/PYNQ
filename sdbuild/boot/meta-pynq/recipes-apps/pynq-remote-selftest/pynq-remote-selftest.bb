SUMMARY = "PYNQ.remote on-target self-test"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://pynq-remote-selftest"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/pynq-remote-selftest ${D}${bindir}/pynq-remote-selftest
}

FILES:${PN} += "${bindir}/pynq-remote-selftest"
