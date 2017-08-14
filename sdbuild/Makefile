
PATH := $(CURDIR)/scripts:$(PATH)

export PATH

WORKDIR_REL ?= .build
WORKDIR := $(CURDIR)/${WORKDIR_REL}
OUTDIR ?= $(CURDIR)/.build/boot_files
CCACHEDIR := $(CURDIR)/.ccache
SCRIPT_DIR := $(CURDIR)/scripts

PYNQ_UPDATE := ${WORKDIR}/PYNQ/.git/HEAD

RELEASE ?= Pynq-Z1-Wily
-include ${WORKDIR}/release_info
BUILD_RELEASE ?= ${RELEASE}

all: checkenv rootfs.img

PYNQ_MASTER_COMMIT := $(shell git rev-parse HEAD)
PYNQ_CLONED_COMMIT := $(shell cd ${WORKDIR}/PYNQ && git rev-parse HEAD)

include releases/${RELEASE}.config
include boot_configs/${BOOT_CONFIG}/config
include rootfs_configs/${ROOTFS_CONFIG}/config

PACKAGES := ${STAGE2_PACKAGES} ${STAGE3_PACKAGES}
PACKAGE_DIRS := $(patsubst %, ${WORKDIR}/packages/%, ${PACKAGES})

-include $(patsubst %, packages/%/Makefile, ${STAGE2_PACKAGES})
STAGE2_PACKAGE_BUILD := ${PACKAGE_BUILD}
PACKAGE_BUILD :=

-include $(patsubst %, packages/%/Makefile, ${STAGE3_PACKAGES})
STAGE3_PACKAGE_BUILD := ${PACKAGE_BUILD}
PACKAGE_BUILD := ${STAGE2_PACKAGE_BUILD} ${STAGE3_PACKAGE_BUILD}

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

${PYNQ_UPDATE}: | ${WORKDIR}/PYNQ
	cd ${WORKDIR}/PYNQ && git fetch origin && git checkout ${PYNQ_MASTER_COMMIT}

ifneq "${PYNQ_MASTER_COMMIT}" "${PYNQ_CLONED_COMMIT}"
.PHONY: ${PYNQ_UPDATE}
endif

${WORKDIR}/board: | ${WORKDIR}
	echo ${BOARD} > $@

${WORKDIR}/rootfs-stage1.img: ${WORKDIR}/multistrap.config ${WORKDIR}/board ${KERNEL_DEB} | ${WORKDIR} ${WORKDIR}/config_diff ${CCACHEDIR}
	sudo -E ${SCRIPT_DIR}/create_mount_img.sh ${WORKDIR_REL}/rootfs-stage1.img ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/create_rootfs.sh ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/unmount_image.sh ${WORKDIR}/rootfs_staging ${WORKDIR_REL}/rootfs-stage1.img

${WORKDIR}/rootfs-stage2.img: ${WORKDIR}/rootfs-stage1.img ${STAGE2_PACKAGE_BUILD} | ${PACKAGE_DIRS}
	cp --sparse=always ${WORKDIR}/rootfs-stage1.img ${WORKDIR}/rootfs-stage2.img
	sudo -E ${SCRIPT_DIR}/mount_image.sh ${WORKDIR_REL}/rootfs-stage2.img ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/install_packages.sh ${WORKDIR}/rootfs_staging ${STAGE2_PACKAGES}
	sudo -E ${SCRIPT_DIR}/unmount_image.sh ${WORKDIR}/rootfs_staging ${WORKDIR_REL}/rootfs-stage2.img

rootfs.img: ${WORKDIR}/rootfs-stage2.img ${BOOT_FILES} ${STAGE3_PACKAGE_BUILD}
	cp --sparse=always ${WORKDIR}/rootfs-stage2.img rootfs.img
	sudo -E ${SCRIPT_DIR}/mount_image.sh rootfs.img ${WORKDIR}/rootfs_staging
	sudo -E cp ${BOOT_FILES} ${WORKDIR}/rootfs_staging/boot
	sudo -E ${SCRIPT_DIR}/install_packages.sh ${WORKDIR}/rootfs_staging ${STAGE3_PACKAGES}
	sudo -E ${SCRIPT_DIR}/cleanup.sh ${WORKDIR}/rootfs_staging
	bash ${SCRIPT_DIR}/resize_umount.sh rootfs.img ${WORKDIR}/rootfs_staging


chroot: rootfs.img
	sudo -E ${SCRIPT_DIR}/mount_image.sh rootfs.img ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/enter_chroot.sh ${WORKDIR}/rootfs_staging
	sudo -E ${SCRIPT_DIR}/cleanup.sh ${WORKDIR}/rootfs_staging

.PHONY: chroot

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

${WORKDIR}/release_info: ${WORKDIR}
	echo "BUILD_RELEASE=${RELEASE}" > $@


checkenv: ${WORKDIR}/release_info
ifeq "${RELEASE}" "${BUILD_RELEASE}"
	which dtc
	which hsi
	which vivado
	which arm-linux-gnueabihf-gcc
	which microblaze-xilinx-elf-gcc
	which ct-ng
	${QEMU_EXE} -version | fgrep 2.8.0
	vivado -version | fgrep 2016.1
	sudo -n true
	bash ${SCRIPT_DIR}/check_Env.sh
	bash ${SCRIPT_DIR}/check_mounts.sh
else
	echo "Release ${BUILD_RELEASE} currently in build area, please run make clean RELEASE=${BUILD_RELEASE} to clean the workspace before building a different release"
	exit 1
endif

clean: checkenv
	-chmod u+w -R .build/gcc-mb
	-rm -rf .build rootfs.img

distclean: clean
	-rm -rf .ccache

.PHONY: checkenv clean distclean
