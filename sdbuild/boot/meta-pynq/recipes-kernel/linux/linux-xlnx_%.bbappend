SRC_URI += " file://pynq.cfg"
SRC_URI += " file://greengrass.cfg"
SRC_URI += " file://wifi.cfg"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
