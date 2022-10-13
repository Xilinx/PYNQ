PYNQ_NOTEBOOK_DIR ?= "/home/root/notebooks"

PYNQ_BOARD ?= ZCU104

do_compile:prepend() {
export PYNQ_JUPYTER_NOTEBOOKS="${D}${PYNQ_NOTEBOOK_DIR}"
export BOARD=${PYNQ_BOARD}
}

do_install:prepend() {
export PYNQ_JUPYTER_NOTEBOOKS="${D}${PYNQ_NOTEBOOK_DIR}"
export BOARD=${PYNQ_BOARD}
}

FILES_${PN}-notebooks = "${PYNQ_NOTEBOOK_DIR}"
PACKAGES += "${PN}-notebooks"
