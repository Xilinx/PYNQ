# Optional per-board u-boot overlay directory (PYNQ_BOARD_UBOOT_DIR, e.g.
# boards/<board>/edf_bsp/u-boot). Every file in the directory is added to the
# u-boot SRC_URI: .patch/.diff files apply in do_patch, .cfg fragments merge
# into the u-boot .config via merge_config.sh in do_configure. Absent/unset ->
# no-op, so boards without a u-boot overlay are unaffected.
PYNQ_BOARD_UBOOT_DIR := "${@d.getVar('BB_ORIGENV', False).getVar('PYNQ_BOARD_UBOOT_DIR', True) or ''}"
FILESEXTRAPATHS:prepend := "${@(d.getVar('PYNQ_BOARD_UBOOT_DIR') + ':') if (d.getVar('PYNQ_BOARD_UBOOT_DIR') and os.path.isdir(d.getVar('PYNQ_BOARD_UBOOT_DIR'))) else ''}"
SRC_URI += "${@' '.join('file://%s' % f for f in sorted(os.listdir(d.getVar('PYNQ_BOARD_UBOOT_DIR')))) if (d.getVar('PYNQ_BOARD_UBOOT_DIR') and os.path.isdir(d.getVar('PYNQ_BOARD_UBOOT_DIR'))) else ''}"
