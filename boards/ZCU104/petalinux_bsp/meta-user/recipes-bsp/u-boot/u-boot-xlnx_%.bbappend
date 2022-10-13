SRC_URI:append = " file://platform-top.h"
SRC_URI += "file://bsp.cfg \
            file://ethernet.cfg \
            "

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
