FILES:${PN} += "${libdir}/librfdc.so"
FILES:${PN}-dev:remove = "${libdir}/*.so"
INSANE_SKIP:${PN} += "dev-so"
