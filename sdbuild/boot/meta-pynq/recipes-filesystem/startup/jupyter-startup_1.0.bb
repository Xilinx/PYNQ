SUMMARY = "Start Jupyter at system boot"

SRC_URI = "file://start-jupyter.sh \
	file://jupyter-setup.sh \
	file://jupyter_notebook_config.py \
	"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://start-jupyter.sh;beginline=2;endline=2;md5=597e9d1b49e840aa57b0269b87bac09e"

RDEPENDS_${PN} += " \
	python3-jupyter \
	"

inherit update-rc.d
INITSCRIPT_PACKAGES = "${PN}"
INITSCRIPT_NAME = "jupyter-setup.sh"
INITSCRIPT_PARAMS = "start 99 S ."

FILES_${PN} += "/usr/sbin/start-jupyter.sh /home/root/.jupyter/jupyter_notebook_config.py"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${INIT_D_DIR}
    install -d ${D}/usr
    install -d ${D}/usr/sbin
    install -d ${D}/home
    install -d ${D}/home/root
    install -d ${D}/home/root/.jupyter

    install -m 0755 ${WORKDIR}/jupyter-setup.sh ${D}${INIT_D_DIR}/jupyter-setup.sh
    install -m 0755 ${WORKDIR}/start-jupyter.sh    ${D}/usr/sbin/start-jupyter.sh
    install -m 0600 ${WORKDIR}/jupyter_notebook_config.py ${D}/home/root/.jupyter

}
