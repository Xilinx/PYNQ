
PATH := $(CURDIR)/scripts:$(PATH)

export PATH

WORKDIR ?= $(CURDIR)/.build
OUTDIR ?= $(CURDIR)/.build/boot_files
CCACHEDIR := $(CURDIR)/.ccache
SCRIPT_DIR := $(CURDIR)/scripts

RELEASE ?= v1.4-Pynq-Z1

all: checkenv rootfs.img

include releases/${RELEASE}.config
include boot_configs/${BOOT_CONFIG}/config
include rootfs_configs/${ROOTFS_CONFIG}/config

PACKAGES := ${STAGE1_PACKAGES} ${STAGE2_PACKAGES}
PACKAGE_DIRS := $(patsubst %, ${WORKDIR}/packages/%, ${PACKAGES})

-include $(patsubst %, packages/%/Makefile, ${PACKAGES})

package_build: ${PACKAGE_BUILD}
package_dirs: ${PACKAGE_DIRS}
patches: ${WORKDIR}/config_diff
boot_files: ${BOOT_FILES} | ${OUTDIR}

.PHONY: package_build package_dirs patches

export WORKDIR
export CCACHEDIR
export QEMU_EXE

${WORKDIR}:
	mkdir -p ${WORKDIR}

${OUTDIR}:
	mkdir -p ${OUTDIR}

${CCACHEDIR}:
	mkdir -p ${CCACHEDIR}

${WORKDIR}/multistrap.config: ${MULTISTRAP_CONFIG} | ${WORKDIR}
	cp $< $@

${WORKDIR}/PYNQ: | ${WORKDIR}
	git clone ../ $@

${WORKDIR}/rootfs-stage1.img: ${WORKDIR}/multistrap.config ${BOOT_FILES}  ${KERNEL_DEB} | ${WORKDIR} ${WORKDIR}/config_diff ${CCACHEDIR}
	sudo -E ${SCRIPT_DIR}/create_mount_img.sh ${WORKDIR}/rootfs-stage1.img ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/create_rootfs.sh ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/unmount_image.sh ${WORKDIR}/rootfs_staging ${WORKDIR}/rootfs-stage1.img

${WORKDIR}/rootfs-stage2.img: ${WORKDIR}/rootfs-stage1.img ${PACKAGE_BUILD} | ${PACKAGE_DIRS}
	cp --sparse=always ${WORKDIR}/rootfs-stage1.img ${WORKDIR}/rootfs-stage2.img
	sudo -E ${SCRIPT_DIR}/mount_image.sh ${WORKDIR}/rootfs-stage2.img ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/install_packages.sh ${WORKDIR}/rootfs_staging ${STAGE1_PACKAGES}
	sudo -E ${SCRIPT_DIR}/unmount_image.sh ${WORKDIR}/rootfs_staging ${WORKDIR}/rootfs-stage2.img

rootfs.img: ${WORKDIR}/rootfs-stage2.img
	cp --sparse=always ${WORKDIR}/rootfs-stage2.img rootfs.img
	sudo -E ${SCRIPT_DIR}/mount_image.sh rootfs.img ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/install_packages.sh ${WORKDIR}/rootfs_staging ${STAGE2_PACKAGES}
	sudo -E ${SCRIPT_DIR}/cleanup.sh ${WORKDIR}/rootfs_staging
	bash ${SCRIPT_DIR}/resize_umount.sh rootfs.img ${WORKDIR}/rootfs_staging


.PRECIOUS: ${WORKDIR}/rootfs-stage1.img ${WORKDIR}/rootfs-stage2.img rootfs.img

${WORKDIR}/packages:
	mkdir -p ${WORKDIR}/packages

${WORKDIR}/packages/%: | ${WORKDIR}/packages
	ln -s $(CURDIR)/packages/$(notdir $@) $@


${WORKDIR}/config_diff:
	mkdir -p $@
	for set in ${PATCHSETS}; do \
		cp -r patchsets/$$set/* $@; \
	done

checkenv:
	which dtc
	which hsi
	which vivado
	which arm-linux-gnueabihf-gcc
	which microblaze-xilinx-elf-gcc
	which ct-ng
	${QEMU_EXE} -version | fgrep 2.8.0
	vivado -version | fgrep 2016.1
	sudo -n true

.PHONY: checkenv
