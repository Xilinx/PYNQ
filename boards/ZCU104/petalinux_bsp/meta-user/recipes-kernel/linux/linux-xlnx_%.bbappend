SRC_URI += "file://bsp.cfg "
SRC_URI += "file://irps5401.patch "
SRC_URI += "file://rollback_pmbus.patch "

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
