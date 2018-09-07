SRC_URI_append = " file://platform-top.h"
SRC_URI += "file://bsp.cfg \
            file://ethernet.cfg \
            "

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
