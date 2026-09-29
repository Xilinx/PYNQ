SRC_URI += " file://pynq.cfg"
SRC_URI += " file://greengrass.cfg"
SRC_URI += " file://wifi.cfg"
SRC_URI += " file://usb_serial.cfg"
SRC_URI += " file://0001-irps5401.patch"
SRC_URI += " file://docker.cfg"
SRC_URI += " file://0001-Change-bMaxBurst-and-qlen-to-the-highest-number.patch"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Optional per-board kernel config fragment (PYNQ_BOARD_KCFG, e.g.
# edf_bsp/kernel.cfg): appended to the kernel SRC_URI when present.
PYNQ_BOARD_KCFG := "${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARD_KCFG', True) or ''}"
FILESEXTRAPATHS:prepend := "${@(os.path.dirname(d.getVar('PYNQ_BOARD_KCFG')) + ':') if (d.getVar('PYNQ_BOARD_KCFG') and os.path.exists(d.getVar('PYNQ_BOARD_KCFG'))) else ''}"
SRC_URI += "${@(' file://' + os.path.basename(d.getVar('PYNQ_BOARD_KCFG'))) if (d.getVar('PYNQ_BOARD_KCFG') and os.path.exists(d.getVar('PYNQ_BOARD_KCFG'))) else ''}"
