SRC_URI:append = " file://platform-top.h"
SRC_URI += " file://0001-add-support-for-artyz.patch"
SRC_URI += " file://0002-add-pynqz1-support.patch"
SRC_URI += " file://0003-add-pynqz2-support.patch"
SRC_URI += " file://ethernet_spi.cfg"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
