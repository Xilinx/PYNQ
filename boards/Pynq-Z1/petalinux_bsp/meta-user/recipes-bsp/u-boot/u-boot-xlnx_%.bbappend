SRC_URI:append = " file://platform-top.h"
SRC_URI += " file://0001-add-support-for-artyz.patch"
SRC_URI += " file://0002-allow-to-read-mac-address-from-SPI-flash.patch"
SRC_URI += " file://0003-add-pynqz1-support.patch"
SRC_URI += " file://0004-allow-to-read-MAC-from-Micron-and-Winbond-flash.patch"
SRC_URI += " file://ethernet_spi.cfg"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
