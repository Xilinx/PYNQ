# Copyright (C) 2022 Xilinx, Inc
# Copyright (C) 2022-2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

ifneq (,$(filter pynqremote,$(MAKECMDGOALS)))
override PYNQREMOTE = 1
endif

# Packages enabled in every PYNQ.remote base rootfs. Boards add
# board-specific remote packages via REMOTE_PACKAGES_<board> in their .spec file.
REMOTE_PACKAGES ?= grpc pynq-cpp

DEFAULT_BOARDDIR := $(CURDIR)/../boards
BOARDDIR ?= $(DEFAULT_BOARDDIR)

# Look for boards and set boarddir to parent directory of single or
# multiple board builds
ALLBOARDS ?= $(basename $(notdir $(wildcard $(BOARDDIR)/*/*.spec))) 
BOARDS ?= $(ALLBOARDS)

UBUNTU_RELEASE := noble
VERSION := 4.0.0

# Vivado/EDF tool version (checked in checkenv).
KERNEL_VERSION := 2025.2
QEMU_VERSION := 8.2
SCRIPT_DIR := $(CURDIR)/scripts
SHELL := /bin/bash

all: real_all

BUILD_ROOT := $(CURDIR)/build
IMAGE_ROOT := $(CURDIR)/output
CCACHEDIR := $(CURDIR)/ccache
ROOTDIR := $(CURDIR)
BOOT_ROOT := $(CURDIR)/output/boot
SDX_ROOT := $(CURDIR)/output/sdx
SYSROOT_ROOT := $(CURDIR)/output/sysroot
BSP_ROOT := $(CURDIR)/output/bsp
DIST_ROOT := $(CURDIR)/output/dist

# aarch64 only (Zynq-7000 deprecated). EDF's xilinx-bootbin builds the boot
# components into BOOT.BIN, so no per-component list is needed.
KERNEL_aarch64 := Image

export CCACHEDIR
export ROOTDIR
export BUILD_ROOT
export BB_ENV_PASSTHROUGH_ADDITIONS := PYNQ_BOARDNAME FPGA_MANAGER PYNQ_BOARD_DTSI
export SHELL

$(IMAGE_ROOT):
	mkdir -p $@

$(BUILD_ROOT):
	mkdir -p $@

$(BOOT_ROOT):
	mkdir -p $@

$(CCACHEDIR):
	mkdir -p $@

$(SDX_ROOT):
	mkdir -p $@

$(SYSROOT_ROOT):
	mkdir -p $@

$(BSP_ROOT):
	mkdir -p $@

$(DIST_ROOT):
	mkdir -p $@

PYNQ_UPDATE := $(BUILD_ROOT)/PYNQ/.git/HEAD
PYNQ_MASTER_COMMIT := $(shell git rev-parse HEAD)
PYNQ_CLONED_COMMIT := $(shell cd $(BUILD_ROOT)/PYNQ 2> /dev/null && git rev-parse HEAD)

$(BUILD_ROOT)/PYNQ: | $(BUILD_ROOT)
	git clone ../ $@
	cd $@ && git submodule init && git submodule update

$(PYNQ_UPDATE): | $(BUILD_ROOT)/PYNQ
	cd $(BUILD_ROOT)/PYNQ && git fetch origin && git checkout $(PYNQ_MASTER_COMMIT)

ifneq "$(PYNQ_MASTER_COMMIT)" "$(PYNQ_CLONED_COMMIT)"
.PHONY: $(PYNQ_UPDATE)
endif

PACKAGE_MAKES := $(wildcard $(CURDIR)/packages/*/Makefile)
include $(PACKAGE_MAKES)
include $(wildcard $(CURDIR)/ubuntu/$(UBUNTU_RELEASE)/*/config)
include $(wildcard $(BOARDDIR)/*/*.spec)

############# BEGIN BOARD_SPECIFIC_RULES ######### 

define BOARD_SPECIFIC_RULES
# $1 is the board name
ifeq ($$(FPGA_MANAGER_$1),)
	FPGA_MANAGER_$1 := 1
endif

# If the board .spec file has rfdc as a remote package we infer it's an RFSoC board
ifeq ($$(RFSoC_$1),)
	RFSoC_$1 := $$(if $$(filter librfdc,$$(REMOTE_PACKAGES_$1)),1,0)
endif

# New API - SDIST and RootFS by default should be provided to the Makefile
# >v2.7     can be overriden to old behavior by setting REBUILD_PYNQ_ROOTFS
#           and REBUILD_PYNQ_SDIST
PYNQ_SDIST ?= $(CURDIR)/prebuilt/pynq_sdist.tar.gz
PYNQ_ROOTFS ?= $(CURDIR)/prebuilt/pynq_rootfs.$$(ARCH_$1).tar.gz

BOARDDIR_$1 := $$(BOARDDIR)/$1
BITSTREAM_ABS_$1 := $$(patsubst %, $$(BOARDDIR_$1)/%, $$(BITSTREAM_$1))

# Build the board's overlay from its own sources. Delete the artefact to
# rebuild it; boards without a BITSTREAM entry have nothing to build.
ifneq ($$(BITSTREAM_$1),)
$$(BITSTREAM_ABS_$1):
	$$(MAKE) -C $$(dir $$(BITSTREAM_ABS_$1))
endif
BUILD_ROOT_$1 := $$(BUILD_ROOT)/$1
BOOT_ROOT_$1 := $$(BOOT_ROOT)/$1
QEMU_$1 := $$(shell which qemu-$$(ARCH_$1)-static)
PACKAGE_ENV_$1 := QEMU_EXE=$$(QEMU_$1) PYNQ_BOARDDIR=$$(BOARDDIR_$1) PYNQ_BOARD=$1 FPGA_MANAGER=$$(FPGA_MANAGER_$1) ARCH=$$(ARCH_$1) PACKAGE_PATH=$$(BOARDDIR_$1)/packages PYNQ_SDIST=$$(PYNQ_SDIST) PYNQ_ROOTFS=$$(PYNQ_ROOTFS) BOOT_ROOT=$$(BOOT_ROOT_$1)
IMAGE_$1 := $$(IMAGE_ROOT)/$1-$$(VERSION).img
REMOTE_IMAGE_$1 := $$(IMAGE_ROOT)/$1-$$(VERSION)-remote.img
ROOT_$1 := $$(BUILD_ROOT)/$1.tar.gz
REMOTE_ROOT_$1 := $$(BUILD_ROOT)/$1.remote_rootfs.tar.gz
SYSROOT_$1 := $$(SYSROOT_ROOT)/$1
EXTRA_BOOT_$1 := $$(BUILD_ROOT)/$1.extra_boot

# ---- EDF boot artefacts (bitbake, via scripts/build_edf_boot.sh) ---------
# Per-board EDF config lives in boards/<board>/edf.env. One script produces
# BOOT.BIN + kernel Image + system.dtb + kernel modules tarball + zocl.ko
# into output/boot/<board>/, replacing the Petalinux boot-artefact flow.
BOARD_EDF_ENV_$1 := $$(BOARDDIR_$1)/edf.env

BOOT_BIN_$1     := $$(BOOT_ROOT_$1)/BOOT.BIN
KERNEL_IMAGE_$1 := $$(BOOT_ROOT_$1)/Image
SYSTEM_DTB_$1   := $$(BOOT_ROOT_$1)/system.dtb
MODULES_$1      := $$(BOOT_ROOT_$1)/modules.tgz
ZOCL_KO_$1      := $$(BOOT_ROOT_$1)/zocl.ko
KERNEL_DEVSRC_$1 := $$(BOOT_ROOT_$1)/kernel-devsrc.rpm
BOOT_FILES_$1   := $$(BOOT_BIN_$1) $$(KERNEL_IMAGE_$1) $$(SYSTEM_DTB_$1) $$(MODULES_$1) $$(ZOCL_KO_$1)
BOOT_STAMP_$1   := $$(BOOT_ROOT_$1)/.boot_built

BOOT_ENV_$1 := BOARD=$1 BOARD_PATH=$$(BOARDDIR_$1) ARCH=$$(ARCH_$1) \
	FPGA_MANAGER=$$(FPGA_MANAGER_$1) OUTPUT_DIR=$$(BOOT_ROOT) ROOTDIR=$$(CURDIR)

$$(BOOT_STAMP_$1): $$(BOARD_EDF_ENV_$1) $$(BITSTREAM_ABS_$1) | $$(BOOT_ROOT_$1)
	$$(BOOT_ENV_$1) $$(SCRIPT_DIR)/build_edf_boot.sh
	touch $$@

$$(BOOT_FILES_$1) $$(KERNEL_DEVSRC_$1): $$(BOOT_STAMP_$1)

boot_$1: $$(BOOT_FILES_$1)
.PHONY: boot_$1

$$(BUILD_ROOT_$1):
	mkdir -p $$@

$$(BOOT_ROOT_$1):
	mkdir -p $$@

BASE_$1 ?= $$(UBUNTU_RELEASE).$$(ARCH_$1).$$(VERSION).tar.gz

ifdef REBUILD_PYNQ_ROOTFS
BASE_PATH_$1 = $$(IMAGE_ROOT)/$$(BASE_$1)
else
BASE_PATH_$1 = $$(PYNQ_ROOTFS)
endif

STAGE4_DEPENDS_$1 := $$(foreach package, $$(STAGE4_PACKAGES_$1), $$(PACKAGE_BUILD_$$(package)_$1) $$(PACKAGE_BUILD_$$(package)))
STAGING_$1 := $$(BUILD_ROOT)/$$(UBUNTU_RELEASE).$1

$$(ROOT_$1) : $$(BASE_PATH_$1) $$(BITSTREAM_ABS_$1) $$(STAGE4_DEPENDS_$1) $$(MODULES_$1) $$(KERNEL_DEVSRC_$1) | $$(CCACHEDIR)
	sudo rm -fr $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	(cd $$(STAGING_$1) && sudo tar -xf $$(realpath $$<))
	# Lay the EDF kernel modules down BEFORE STAGE4: xrt's pre.sh drops
	# zocl.ko into /lib/modules/<kver>/extra, so the modules tree must exist.
	mkdir -p $$(BUILD_ROOT_$1)/modules
	cd $$(BUILD_ROOT_$1)/modules && tar -xf $$(MODULES_$1)
	sudo cp -r --no-preserve=ownership $$(BUILD_ROOT_$1)/modules/lib/* $$(STAGING_$1)/usr/lib/
	rm -rf $$(BUILD_ROOT_$1)/modules
	# On-target kernel build tree (/usr/src/kernel + /lib/modules/<kver>/build).
	rpm2cpio $$(KERNEL_DEVSRC_$1) | ( cd $$(STAGING_$1) && sudo cpio -idmu )
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/install_packages.sh $$(STAGING_$1) $$(STAGE4_PACKAGES_$1)
	sudo mount -o bind /dev $$(STAGING_$1)/dev
	echo "depmod -a \`ls /lib/modules\`" > $$(STAGING_$1)/depmod.sh
	chmod a+x $$(STAGING_$1)/depmod.sh
	sudo chroot $$(STAGING_$1) /bin/bash -c "/depmod.sh"
	rm $$(STAGING_$1)/depmod.sh
	sudo umount -l $$(STAGING_$1)/dev
	rm -rf $$(EXTRA_BOOT_$1)
	cp -r $$(STAGING_$1)/boot $$(EXTRA_BOOT_$1)

	# Clean up any unwanted user directories created during build process
	# Only keep the xilinx user directory
	sudo find $$(STAGING_$1)/home -mindepth 1 -maxdepth 1 -type d ! -name "xilinx" -exec rm -rf {} + 2>/dev/null || true
	
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)


# Build the SD image (FAT32 boot + ext4 root); see scripts/make_sdimage.sh.
$$(IMAGE_$1) : $$(ROOT_$1) $$(BOOT_FILES_$1) | $$(IMAGE_ROOT)
	ROOTFS_TAR=$$(ROOT_$1) BOOT_DIR=$$(BOOT_ROOT_$1) OUT_IMG=$$@ \
		EXTRA_BOOT=$$(EXTRA_BOOT_$1) \
		$$(SCRIPT_DIR)/make_sdimage.sh



# ---- PYNQ.remote appliance image (EDF/bitbake minimal rootfs) ----
REMOTE_ENV_$1 := BOARD=$1 BOARD_PATH=$$(BOARDDIR_$1) ARCH=$$(ARCH_$1) \
	ROOTDIR=$$(CURDIR) REMOTE_ROOTFS_OUT=$$(REMOTE_ROOT_$1) \
	REMOTE_PACKAGES="$$(REMOTE_PACKAGES) $$(REMOTE_PACKAGES_$1)" RFSoC=$$(RFSoC_$1)

$$(REMOTE_ROOT_$1) : $$(BOARD_EDF_ENV_$1) $$(BOOT_STAMP_$1) | $$(BUILD_ROOT)
	$$(REMOTE_ENV_$1) $$(SCRIPT_DIR)/build_edf_remote_rootfs.sh

$$(REMOTE_IMAGE_$1) : $$(REMOTE_ROOT_$1) $$(BOOT_FILES_$1) | $$(IMAGE_ROOT)
	ROOTFS_TAR=$$(REMOTE_ROOT_$1) BOOT_DIR=$$(BOOT_ROOT_$1) OUT_IMG=$$@ \
		ROOT_MARGIN_MB=256 \
		$$(SCRIPT_DIR)/make_sdimage.sh

pynqremote_$1: $$(REMOTE_IMAGE_$1)
	echo "Done building remote image for board $1"

SDX_DIR_$1 := $$(SDX_ROOT)/$1/sw
SDX_LINUX_DIR_$1 := $$(SDX_DIR_$1)/linux
SDX_BOOT_DIR_$1 := $$(SDX_DIR_$1)/boot
SDX_IMAGE_DIR_$1 := $$(SDX_LINUX_DIR_$1)/image
SDX_FILES_$1 := $$(SDX_IMAGE_DIR_$1)/image.ub $$(patsubst %, $$(SDX_BOOT_DIR_$1)/%, $$(BOOT_$$(ARCH_$1))) $$(SDX_LINUX_DIR_$1)/linux.bif $$(SDX_DIR_$1)/generic.readme

$$(SDX_DIR_$1): | $$(SDX_ROOT)
	mkdir -p $$@

$$(SDX_LINUX_DIR_$1): | $$(SDX_DIR_$1)
	mkdir -p $$@

$$(SDX_BOOT_DIR_$1): | $$(SDX_DIR_$1)
	mkdir -p $$@

$$(SDX_IMAGE_DIR_$1): | $$(SDX_LINUX_DIR_$1)
	mkdir -p $$@

$$(SDX_BOOT_DIR_$1)/%: $$(PL_PROJ_$1)/images/linux/% | $$(SDX_BOOT_DIR_$1)
	cp $$< $$@

$$(SDX_LINUX_DIR_$1)/linux.bif: $$(CURDIR)/boot/linux_$$(ARCH_$1).bif | $$(SDX_LINUX_DIR_$1)
	cp $$< $$@

$$(SDX_DIR_$1)/generic.readme: $$(CURDIR)/boot/generic.readme | $$(SDX_DIR_$1)
	cp $$< $$@

$$(SDX_IMAGE_DIR_$1)/image.ub: $$(BOOT_ROOT_$1)/image.ub | $$(SDX_IMAGE_DIR_$1)
	cp $$< $$@

sdx_sw_$1: $$(SDX_FILES_$1)

$$(SYSROOT_$1): $$(ROOT_$1) | $$(SYSROOT_ROOT)
	-rm -rf $$@
	mkdir -p $$@/usr $$@/lib $$@/opt
	(cd $$@ && tar -xf $$(ROOT_$1) usr lib opt)
	sudo chmod a+w -R $$@

sysroot_$1 : $$(SYSROOT_$1)

.PHONY: sysroot_$1 sdx_sw_$1

endef ### BOARD SPECIFIC RULES ###


############# BEGIN ARCH_SPECIFIC_RULES #########
define ARCH_SPECIFIC_RULES
# $1 is the architecture
# Used to generate the board-independent root filesystems
BASE_$1 := $$(IMAGE_ROOT)/$$(UBUNTU_RELEASE).$1.$$(VERSION).tar.gz
STAGING_$1 := $$(BUILD_ROOT)/$$(UBUNTU_RELEASE).$1
STAGE1_$1 := $$(BUILD_ROOT)/$$(UBUNTU_RELEASE).$1.stage1.tar.gz
STAGE2_$1 := $$(BUILD_ROOT)/$$(UBUNTU_RELEASE).$1.stage2.tar.gz
STAGE2_DEPENDS_$1 := $$(foreach package, $$(STAGE2_PACKAGES_$1), $$(PACKAGE_BUILD_$$(package)_$1) $$(PACKAGE_BUILD_$$(package)))
STAGE3_DEPENDS_$1 := $$(foreach package, $$(STAGE3_PACKAGES_$1), $$(PACKAGE_BUILD_$$(package)_$1) $$(PACKAGE_BUILD_$$(package)))
CONFIG_$1 := $$(CURDIR)/ubuntu/$$(UBUNTU_RELEASE)/$1
QEMU_$1 := $$(shell which qemu-$1-static)
PACKAGE_ENV_$1 := QEMU_EXE=$$(QEMU_$1) PYNQ_BOARD=Unknown ARCH=$1 PYNQ_SDIST=$(PYNQ_SDIST) PYNQ_ROOTFS=$(PYNQ_ROOTFS)

ifdef REBUILD_PYNQ_SDIST
SDIST_PATH_$1 = $$(BUILD_ROOT)/PYNQ/dist/*.tar.gz
else
SDIST_PATH_$1 = $$(PYNQ_SDIST)
endif

DIST_$1 := $$(DIST_ROOT)/$1

$$(STAGE2_$1) : $$(STAGE1_$1) $$(STAGE2_DEPENDS_$1) | $$(CCACHEDIR)
	sudo rm -rf $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	(cd $$(STAGING_$1) && sudo tar -xf $$<)
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/install_packages.sh $$(STAGING_$1) $$(STAGE2_PACKAGES_$1)
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)

$$(BASE_$1) : $$(STAGE2_$1) $$(STAGE3_DEPENDS_$1) | $$(IMAGE_ROOT) $$(CCACHEDIR)
	sudo rm -rf $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	(cd $$(STAGING_$1) && sudo tar -xf $$<)
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/install_packages.sh $$(STAGING_$1) $$(STAGE3_PACKAGES_$1)
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)

$$(STAGE1_$1): $$(CONFIG_$1)/multistrap.config | $$(BUILD_ROOT) $$(CCACHEDIR)
	sudo rm -rf $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/create_rootfs.sh $$(STAGING_$1) $$(CONFIG_$1) $$(ARCH_$1)
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)

qemu_check_$1:
	$$(QEMU_$1) -version | fgrep ${QEMU_VERSION}

$$(DIST_$1): $$(BASE_PATH_$1) | $$(DIST_ROOT)
	mkdir -p $$@
	cp -rf $$(SDIST_PATH_$1) $$@

dist_$1: $$(DIST_$1)

.PHONY: qemu_check_$1 dist_$1

endef  ### ARCH SPECIFIC RULES ###

ifeq ($(ARCH_ONLY),)
USED_ARCH := $(sort $(foreach board, $(BOARDS), $(value ARCH_$(board))))
$(foreach board, $(BOARDS), $(eval $(call BOARD_SPECIFIC_RULES,$(board))))
$(foreach arch, $(USED_ARCH), $(eval $(call ARCH_SPECIFIC_RULES,$(arch))))
IMAGE_FILES := $(foreach image_var, $(patsubst %, IMAGE_%, $(BOARDS)), $(value $(image_var)))
else
USED_ARCH := $(ARCH_ONLY)
$(foreach arch, $(USED_ARCH), $(eval $(call ARCH_SPECIFIC_RULES,$(arch))))
IMAGE_FILES := $(foreach image_var, $(patsubst %, BASE_%, $(ARCH_ONLY)), $(value $(image_var)))
endif


DIST_FILES := $(foreach dist_var, $(patsubst %, DIST_%, $(USED_ARCH)), $(value $(dist_var)))
BSP_FILES := $(foreach bsp_var, $(patsubst %, BSP_FILES_%, $(BOARDS)), $(value $(bsp_var)))
BOOT_FILES := $(foreach boot_var, $(patsubst %, BOOT_FILES_%, $(BOARDS)), $(value $(boot_var)))
ALL_PACKAGES := $(sort $(foreach board, $(BOARDS), $(value STAGE3_PACKAGES_$(board)) $(value STAGE4_PACKAGES_$(board))) \
		$(foreach arch, $(USED_ARCH), $(value STAGE2_PACKAGES_$(arch)) $(value STAGE3_PACKAGES_$(arch))))
PACKAGE_CLEAN := $(patsubst %,PACKAGE_CLEAN_%, $(ALL_PACKAGES))

checkenv: $(patsubst %, qemu_check_%, $(USED_ARCH))
ifeq ($(BOARDS),)
	$(error No board .spec files found... please check BOARDDIR path: $(BOARDDIR))
endif

ifndef REBUILD_PYNQ_SDIST
ifeq ($(wildcard $(PYNQ_SDIST)),)
	$(error REBUILD_PYNQ_SDIST not set and PYNQ_SDIST file $(PYNQ_SDIST) does not exist)
endif
endif

ifndef REBUILD_PYNQ_ROOTFS
ifeq ($(wildcard $(PYNQ_ROOTFS)),)
	$(error REBUILD_PYNQ_ROOTFS not set and PYNQ_ROOTFS file $(PYNQ_ROOTFS) does not exist)
endif
endif

	vivado -version | fgrep ${KERNEL_VERSION}
	vitis -version | fgrep ${KERNEL_VERSION}
ifdef REBUILD_PYNQ_SDIST
	which microblaze-xilinx-elf-gcc
endif
ifdef REBUILD_PYNQ_ROOTFS
	which ct-ng
endif
	bash $(SCRIPT_DIR)/check_env.sh

boot_files: checkenv $(BOOT_FILES)

images: checkenv $(IMAGE_FILES)

nocheck_images: $(IMAGE_FILES)

real_all: checkenv $(BOOT_FILES) $(IMAGE_FILES) $(DIST_FILES)

sdx_sw: $(patsubst %, sdx_sw_%, $(BOARDS))

sysroot: $(patsubst %, sysroot_%, $(BOARDS))

bsp: $(patsubst %, bsp_%, $(BOARDS))

dist: $(patsubst %, dist_%, $(USED_ARCH))

pynqremote: $(patsubst %, pynqremote_%, $(BOARDS))

# Default package clean target
PACKAGE_CLEAN_%: ;

clean: $(PACKAGE_CLEAN)
	-rm -rf $(BUILD_ROOT)
	-rm -rf $(IMAGE_ROOT)

.PHONY: dist bsp boot_files images all clean \
	real_all checkenv sdx_sw sysroot nocheck_images
