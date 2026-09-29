SUMMARY = "PYNQ.remote appliance networking (systemd-networkd DHCP)"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://80-wired.network"
S = "${WORKDIR}"

RDEPENDS:${PN} = "systemd"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/80-wired.network ${D}${sysconfdir}/systemd/network/80-wired.network

    # Enable systemd-networkd (and its socket) + resolved at boot.
    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_system_unitdir}/systemd-networkd.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-networkd.service
    ln -sf ${systemd_system_unitdir}/systemd-resolved.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-resolved.service
    install -d ${D}${sysconfdir}/systemd/system/sockets.target.wants
    ln -sf ${systemd_system_unitdir}/systemd-networkd.socket \
        ${D}${sysconfdir}/systemd/system/sockets.target.wants/systemd-networkd.socket
}

FILES:${PN} += " \
    ${sysconfdir}/systemd/network/80-wired.network \
    ${sysconfdir}/systemd/system/multi-user.target.wants/systemd-networkd.service \
    ${sysconfdir}/systemd/system/multi-user.target.wants/systemd-resolved.service \
    ${sysconfdir}/systemd/system/sockets.target.wants/systemd-networkd.socket \
"
