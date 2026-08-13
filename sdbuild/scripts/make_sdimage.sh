#!/usr/bin/env bash
#
# Assemble a bootable ZynqMP SD-card image.
#
# Produces an MBR image with two partitions, matching boot/image.wks:
#   p1  FAT32  label PYNQ  (bootable)  -- BOOT.BIN + Image + system.dtb + extlinux
#   p2  ext4   label root              -- the board root filesystem
#
# The root partition is sized to just hold the rootfs plus a small margin; the
# resizefs first-boot service grows it to fill the SD card.
#
# Env inputs (set by the Makefile):
#   ROOTFS_TAR   board rootfs tarball (build/<board>.tar.gz)
#   BOOT_DIR     dir with BOOT.BIN, Image, system.dtb, extlinux/ (output/boot/<board>)
#   OUT_IMG      output image path (output/<board>-<version>.img)
#   EXTRA_BOOT   optional dir whose contents are copied into the boot partition
#   BOOT_SIZE_MB boot partition size in MiB (default 100)
#   ROOT_MARGIN_MB spare MiB added on top of the rootfs size (default 1024)

set -euo pipefail

ROOTFS_TAR="${ROOTFS_TAR:?ROOTFS_TAR must be set}"
BOOT_DIR="${BOOT_DIR:?BOOT_DIR must be set}"
OUT_IMG="${OUT_IMG:?OUT_IMG must be set}"
EXTRA_BOOT="${EXTRA_BOOT:-}"
BOOT_SIZE_MB="${BOOT_SIZE_MB:-100}"
ROOT_MARGIN_MB="${ROOT_MARGIN_MB:-1024}"

[ -f "${ROOTFS_TAR}" ] || { echo "ERROR: rootfs tarball not found: ${ROOTFS_TAR}" >&2; exit 1; }
[ -f "${BOOT_DIR}/BOOT.BIN" ] || { echo "ERROR: BOOT.BIN not found in ${BOOT_DIR}" >&2; exit 1; }
[ -f "${BOOT_DIR}/Image" ]    || { echo "ERROR: Image not found in ${BOOT_DIR}" >&2; exit 1; }
[ -f "${BOOT_DIR}/system.dtb" ] || { echo "ERROR: system.dtb not found in ${BOOT_DIR}" >&2; exit 1; }
[ -f "${BOOT_DIR}/extlinux/extlinux.conf" ] || { echo "ERROR: extlinux/extlinux.conf not found in ${BOOT_DIR}" >&2; exit 1; }

# ---- cleanup on exit -------------------------------------------------------
# The build container has no udev, so `losetup -P` does not create per-partition
# device nodes. We instead attach one offset/size-limited loop device per
# partition, which needs no partition-scan nodes.
MNT_BOOT=""; MNT_ROOT=""; BOOT_LOOP=""; ROOT_LOOP=""
cleanup() {
    set +e
    [ -n "${MNT_BOOT}" ] && mountpoint -q "${MNT_BOOT}" && sudo umount "${MNT_BOOT}"
    [ -n "${MNT_ROOT}" ] && mountpoint -q "${MNT_ROOT}" && sudo umount "${MNT_ROOT}"
    [ -n "${BOOT_LOOP}" ] && sudo losetup -d "${BOOT_LOOP}" 2>/dev/null
    [ -n "${ROOT_LOOP}" ] && sudo losetup -d "${ROOT_LOOP}" 2>/dev/null
    [ -n "${MNT_BOOT}" ] && rmdir "${MNT_BOOT}" 2>/dev/null
    [ -n "${MNT_ROOT}" ] && rmdir "${MNT_ROOT}" 2>/dev/null
}
trap cleanup EXIT

echo "============================================"
echo "SD image assembly"
echo "  rootfs:  ${ROOTFS_TAR}"
echo "  boot:    ${BOOT_DIR}"
echo "  output:  ${OUT_IMG}"
echo "============================================"

# ---- size the root partition from the uncompressed rootfs ------------------
echo "--- Measuring rootfs (uncompressed) ---"
ROOTFS_BYTES=$(zcat "${ROOTFS_TAR}" | wc -c)
ROOTFS_MB=$(( (ROOTFS_BYTES + 1048575) / 1048576 ))
ROOT_SIZE_MB=$(( ROOTFS_MB + ROOT_MARGIN_MB ))
echo "  rootfs ~${ROOTFS_MB} MiB -> root partition ${ROOT_SIZE_MB} MiB"

# Layout: 4 MiB gap, boot (BOOT_SIZE_MB), root (ROOT_SIZE_MB), + 8 MiB slack.
GAP_MB=4
TOTAL_MB=$(( GAP_MB + BOOT_SIZE_MB + ROOT_SIZE_MB + 8 ))
BOOT_START_MB=${GAP_MB}
BOOT_END_MB=$(( BOOT_START_MB + BOOT_SIZE_MB ))
ROOT_START_MB=${BOOT_END_MB}

echo "--- Creating ${TOTAL_MB} MiB image ---"
rm -f "${OUT_IMG}"
truncate -s "${TOTAL_MB}M" "${OUT_IMG}"

echo "--- Partitioning (MBR: FAT32 boot + ext4 root) ---"
parted -s "${OUT_IMG}" mklabel msdos
parted -s "${OUT_IMG}" unit MiB mkpart primary fat32 "${BOOT_START_MB}" "${BOOT_END_MB}"
parted -s "${OUT_IMG}" unit MiB mkpart primary ext4 "${ROOT_START_MB}" 100%
parted -s "${OUT_IMG}" set 1 boot on

# Read exact byte offsets/sizes parted assigned to each partition.
read_part() { # $1 = partition number -> echoes "START_BYTES SIZE_BYTES"
    parted -m -s "${OUT_IMG}" unit B print | awk -F: -v n="$1" \
        '$1==n { gsub(/B/,"",$2); gsub(/B/,"",$4); print $2, $4 }'
}
read BOOT_OFF BOOT_LEN < <(read_part 1)
read ROOT_OFF ROOT_LEN < <(read_part 2)
[ -n "${BOOT_OFF}" ] && [ -n "${ROOT_OFF}" ] || { echo "ERROR: could not read partition geometry" >&2; exit 1; }
echo "  boot: offset=${BOOT_OFF} len=${BOOT_LEN}"
echo "  root: offset=${ROOT_OFF} len=${ROOT_LEN}"

echo "--- Attaching loop devices (per-partition, offset-based) ---"
# No udev in the container: `losetup -f` can return a device whose /dev node is
# missing. Create the node ourselves (major 7) and attach it explicitly.
attach_loop() { # $1=offset $2=len -> echoes device path
    local off="$1" len="$2" n dev
    for n in $(seq 0 63); do
        dev="/dev/loop${n}"
        [ -e "${dev}" ] || sudo mknod "${dev}" b 7 "${n}" 2>/dev/null || true
        if sudo losetup --offset "${off}" --sizelimit "${len}" "${dev}" "${OUT_IMG}" 2>/dev/null; then
            echo "${dev}"; return 0
        fi
    done
    return 1
}
BOOT_LOOP=$(attach_loop "${BOOT_OFF}" "${BOOT_LEN}") || { echo "ERROR: could not attach boot loop" >&2; exit 1; }
ROOT_LOOP=$(attach_loop "${ROOT_OFF}" "${ROOT_LEN}") || { echo "ERROR: could not attach root loop" >&2; exit 1; }
echo "  boot -> ${BOOT_LOOP}"
echo "  root -> ${ROOT_LOOP}"

echo "--- Formatting ---"
sudo mkfs.vfat -F 32 -n PYNQ "${BOOT_LOOP}"
sudo mkfs.ext4 -F -L root "${ROOT_LOOP}"

MNT_BOOT=$(mktemp -d); MNT_ROOT=$(mktemp -d)

echo "--- Populating boot partition ---"
sudo mount "${BOOT_LOOP}" "${MNT_BOOT}"
if [ -n "${EXTRA_BOOT}" ] && [ -d "${EXTRA_BOOT}" ]; then
    sudo cp -r "${EXTRA_BOOT}"/. "${MNT_BOOT}"/ 2>/dev/null || true
fi
# Authoritative EDF boot artefacts win over anything from the rootfs /boot.
sudo cp "${BOOT_DIR}/BOOT.BIN" "${MNT_BOOT}/BOOT.BIN"
sudo cp "${BOOT_DIR}/Image" "${MNT_BOOT}/Image"
sudo cp "${BOOT_DIR}/system.dtb" "${MNT_BOOT}/system.dtb"
sudo mkdir -p "${MNT_BOOT}/extlinux"
sudo cp "${BOOT_DIR}/extlinux/extlinux.conf" "${MNT_BOOT}/extlinux/extlinux.conf"
# Optional autoboot glue (Versal ships boot.scr / uEnv.txt / uboot.env).
for f in boot.scr boot.scr.uimg uEnv.txt uboot.env; do
    [ -f "${BOOT_DIR}/${f}" ] && sudo cp "${BOOT_DIR}/${f}" "${MNT_BOOT}/${f}"
done
sync
sudo umount "${MNT_BOOT}"; mountpoint -q "${MNT_BOOT}" || MNT_BOOT=""

echo "--- Extracting rootfs into root partition ---"
sudo mount "${ROOT_LOOP}" "${MNT_ROOT}"
( cd "${MNT_ROOT}" && sudo tar --numeric-owner -xzf "${ROOTFS_TAR}" )
sync
sudo umount "${MNT_ROOT}"; mountpoint -q "${MNT_ROOT}" || MNT_ROOT=""

echo "--- Detaching loop devices ---"
sudo losetup -d "${BOOT_LOOP}"; BOOT_LOOP=""
sudo losetup -d "${ROOT_LOOP}"; ROOT_LOOP=""

echo "============================================"
echo "SD image ready: ${OUT_IMG}"
ls -lh "${OUT_IMG}"
echo "============================================"
