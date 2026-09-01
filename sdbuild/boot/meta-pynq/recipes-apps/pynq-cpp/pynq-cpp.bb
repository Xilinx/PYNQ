SUMMARY = "PYNQ.remote build"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "protobuf grpc protobuf-native grpc-native xrt"

# RFSoC services (xrfdc, xrfclk) are gated by the "rfsoc" PACKAGECONFIG.
# The PYNQ Makefile writes a per-project bbappend that appends "rfsoc" to
# PACKAGECONFIG when RFSoC_<board>=1.
PACKAGECONFIG ??= ""
PACKAGECONFIG[rfsoc] = "-DRFSOC=ON,-DRFSOC=OFF,librfdc libmetal,librfdc libmetal"

SRC_URI = "file://cpp/CMakeLists.txt \
           file://cpp/pynq-remote.cc \
           file://cpp/device.cc \
           file://cpp/device.h \
           file://cpp/mmio.cc \
           file://cpp/mmio.h \
           file://cpp/buffer.cc \
           file://cpp/buffer.h \
           file://cpp/gpio.cc \
           file://cpp/gpio.h \
           file://cpp/interrupt.cc \
           file://cpp/interrupt.h \
           file://protos/buffer.proto \
           file://protos/gpio.proto \
           file://protos/mmio.proto \
           file://protos/interrupt.proto \
           file://protos/remote_device.proto \
           file://cmake/common.cmake \
           file://pynq-remote.service"

SRC_URI:append = " ${@bb.utils.contains('PACKAGECONFIG', 'rfsoc', \
    'file://cpp/xrfclk.cc file://cpp/xrfclk.h \
     file://cpp/xrfdc.cc file://cpp/xrfdc.h \
     file://protos/xrfclk.proto file://protos/xrfdc.proto', '', d)}"

S = "${WORKDIR}/cpp"

inherit cmake deploy systemd


SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "pynq-remote.service"
FILES:${PN} += "/lib/systemd/system/pynq-remote.service"

do_configure:prepend() {
    export CMAKE_LIBRARY_PATH="${STAGING_LIBDIR}:${STAGING_DIR_HOST}/usr/lib"
    export CMAKE_INCLUDE_PATH="${STAGING_INCDIR}:${STAGING_DIR_HOST}/usr/include"
    export GRPC_CPP_PLUGIN="${STAGING_DIR_HOST}/usr/bin/grpc_cpp_plugin"
    export Protobuf_PROTOC_EXECUTABLE="${STAGING_DIR_HOST}/usr/bin/protoc"
    export Protobuf_DIR="${STAGING_LIBDIR}/cmake/protobuf"
}

do_deploy() {
    install -m 0755 ${B}/pynq-remote ${DEPLOY_DIR}/
}

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${B}/pynq-remote ${D}/${bindir}/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/pynq-remote.service ${D}${systemd_system_unitdir}/
}
