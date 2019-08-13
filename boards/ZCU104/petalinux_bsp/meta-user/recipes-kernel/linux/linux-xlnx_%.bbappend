SRC_URI += "file://bsp.cfg "
SRC_URI += "file://0001-irps5401.patch "
SRC_URI += "file://0002-rollback-pmbus.patch "

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
