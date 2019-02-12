SUMMARY = "Xilinx PYNQ Library"
HOMEPAGE = "http://pynq.io"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b42e39ad2ddbad7e8ad47f3eee6feff5"
RDEPENDS_${PN} += "\
${PYTHON_PN}-core \
${PYTHON_PN}-asyncio \
${PYTHON_PN}-cffi \
${PYTHON_PN}-importlib \
${PYTHON_PN}-json \
${PYTHON_PN}-math \
${PYTHON_PN}-mmap \
${PYTHON_PN}-multiprocessing \
${PYTHON_PN}-numpy \
${PYTHON_PN}-pycparser \
${PYTHON_PN}-re \
${PYTHON_PN}-resource \
${PYTHON_PN}-setuptools \
${PYTHON_PN}-signal \
${PYTHON_PN}-subprocess \
${PYTHON_PN}-threading \
${PYTHON_PN}-xml \
lmsensors-libsensors \
libdrm \
"

DEPENDS += " libdrm boost"

PYNQ_ARCH_arm = "armv7l"
PYNQ_ARCH_aarch64 = "aarch64"
CMA_ARCH_arm = "32"
CMA_ARCH_aarch64 = "64"

SRC_URI = "gitsm://${THISDIR}/../../../../../;usehead=1;protocol=file"
SRCREV = "${AUTOREV}"

SRC_URI += " file://pl_server_init"
FILESEXTRAPATHS_prepend := "${THISDIR}:"
S = "${WORKDIR}/git"
INSANE_SKIP_${PN} = "staticdev"
BBCLASSEXTEND = "native nativesdk"

inherit update-rc.d
INITSCRIPT_PACKAGES = "${PN}"
INITSCRIPT_NAME = "pl_server_init"
INITSCRIPT_PARAMS = "start 99 S ."

do_compile_prepend() {
install -d "${D}/home/root/notebooks"
export PYNQ_JUPYTER_NOTEBOOKS="${D}/home/root/notebooks"
export PYNQ_BUILD_ARCH="${PYNQ_ARCH_${TARGET_ARCH}}"
export PYNQ_BUILD_ROOT="${STAGING_DIR_TARGET}"
 (cd ${S}/sdbuild/packages/libsds/libcma && CMA_ARCH=${CMA_ARCH_${TARGET_ARCH}} make install DESTDIR=${STAGING_DIR_TARGET})

}

do_install_prepend() {
install -d "${D}/home/root/notebooks"
export PYNQ_JUPYTER_NOTEBOOKS="${D}/home/root/notebooks"
export PYNQ_BUILD_ARCH="${PYNQ_ARCH_${TARGET_ARCH}}"
export PYNQ_BUILD_ROOT="${STAGING_DIR_TARGET}"
}

do_install_append() {
 install -d ${D}${INIT_D_DIR}
 install -m 755 ${WORKDIR}/pl_server_init ${D}${INIT_D_DIR}/pl_server_init
 (cd ${S}/sdbuild/packages/libsds/libcma && CMA_ARCH=${CMA_ARCH_${TARGET_ARCH}} make install DESTDIR=${D})
 rm -rf ${D}/home/root/notebooks_*
}

SOLIBS = ".so"
FILES_SOLIBSDEV = ""
FILES_${PN} += " ${INIT_D_DIR}/pl_server_init /usr/lib/libcma.so"
FILES_${PN}-notebooks = "/home/root/notebooks"
PACKAGES += "${PN}-notebooks"
