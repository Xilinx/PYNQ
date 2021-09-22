DEFAULT_BOARDDIR := $(CURDIR)/../boards
BOARDDIR ?= $(DEFAULT_BOARDDIR)
BOARDS ?= $(basename $(notdir $(wildcard $(BOARDDIR)/*/*.spec)))
UBUNTU_RELEASE := focal
VERSION := 2.7.0

KERNEL_VERSION := 2020.2
LINUX_VERSION := 5.4.0-xilinx-v2020.2
QEMU_VERSION := 5.2.0
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

KERNEL_arm := zImage
KERNEL_aarch64 := Image
BOOT_arm := u-boot.elf zynq_fsbl.elf
BOOT_aarch64 := u-boot.elf zynqmp_fsbl.elf pmufw.elf bl31.elf

export CCACHEDIR
export ROOTDIR
export BUILD_ROOT
export BB_ENV_EXTRAWHITE := PYNQ_BOARDNAME FPGA_MANAGER
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

define BOARD_SPECIFIC_RULES
# $1 is the board name
ifeq ($$(FPGA_MANAGER_$1),)
	FPGA_MANAGER_$1 := 1
endif

BOARDDIR_$1 := $$(BOARDDIR)/$1
BITSTREAM_ABS_$1 := $$(patsubst %, $$(BOARDDIR_$1)/%, $$(BITSTREAM_$1))
BUILD_ROOT_$1 := $$(BUILD_ROOT)/$1
BOOT_ROOT_$1 := $$(BOOT_ROOT)/$1
QEMU_$1 := $$(shell which qemu-$$(ARCH_$1)-static)
PACKAGE_ENV_$1 := QEMU_EXE=$$(QEMU_$1) PYNQ_BOARDDIR=$$(BOARDDIR_$1) PYNQ_BOARD=$1 FPGA_MANAGER=$$(FPGA_MANAGER_$1) ARCH=$$(ARCH_$1) PACKAGE_PATH=$$(BOARDDIR_$1)/packages
IMAGE_$1 := $$(IMAGE_ROOT)/$1-$$(VERSION).img
ROOT_$1 := $$(BUILD_ROOT)/$1.tar.gz
SYSROOT_$1 := $$(SYSROOT_ROOT)/$1
EXTRA_BOOT_$1 := $$(BUILD_ROOT)/$1.extra_boot

ifeq ($$(ARCH_$1),arm)
	TEMPLATE_$1 := zynq
endif
ifeq ($$(ARCH_$1),aarch64)
	TEMPLATE_$1 := zynqMP
endif

BSP_BUILD_$1 := $$(BUILD_ROOT_$1)/petalinux_bsp
BSP_ABS_$1 := $$(patsubst %,$$(BOARDDIR_$1)/%,$$(BSP_$1))
BSP_PROJECT_$1 := xilinx-$$(shell echo $1 | tr A-Z a-z | tr -cd '[:alnum:]')-$$(KERNEL_VERSION)
BSP_TARGET_$1 := $$(BSP_BUILD_$1)/$$(BSP_PROJECT_$1).bsp
BSP_ENV_$1 := BSP=$$(BSP_$1) BSP_BUILD=$$(BSP_BUILD_$1) BSP_ABS=$$(BSP_ABS_$1) BSP_PROJECT=$$(BSP_PROJECT_$1)

$$(BSP_BUILD_$1): | $$(BUILD_ROOT_$1)
	-rm -rf $$(BSP_BUILD_$1)
	mkdir -p $$(BSP_BUILD_$1)

$$(BSP_TARGET_$1): | $$(BSP_BUILD_$1)
	$$(BSP_ENV_$1) $$(SCRIPT_DIR)/create_bsp.sh $$(BOARDDIR_$1) $$(TEMPLATE_$1)

# BSP Specific Rules
BSP_DIR_$1 := $$(BSP_ROOT)/$1
BSP_FILES_$1 := $$(BSP_DIR_$1)/$$(BSP_PROJECT_$1).bsp

$$(BSP_DIR_$1): | $$(BSP_ROOT)
	mkdir -p $$@

$$(BSP_DIR_$1)/$$(BSP_PROJECT_$1).bsp: $$(BSP_TARGET_$1) | $$(BSP_DIR_$1)
	cp $$< $$@

bsp_$1: $$(BSP_FILES_$1)

.PHONY: bsp_$1

PL_PROJ_$1 := $$(BUILD_ROOT_$1)/petalinux_project
PL_CONFIG_$1 := $$(PL_PROJ_$1)/project-spec/configs/config
PL_ROOTFS_CONFIG_$1 := $$(PL_PROJ_$1)/project-spec/configs/rootfs_config
MODULES_$1 := $$(PL_PROJ_$1)/build/tmp/deploy/images/modules-plnx_$$(ARCH_$1).tgz
KERNEL_RPM_$1 := $$(PL_PROJ_$1)/build/tmp/deploy/rpm/kernel-devsrc-1.0-r0.plnx_$$(ARCH_$1).rpm
PL_ENV_$1 := PYNQ_BOARDNAME=$1 FPGA_MANAGER=$$(FPGA_MANAGER_$1)

BOOT_FILES_$1 := $$(BOOT_ROOT_$1)/image.ub $$(BOOT_ROOT_$1)/BOOT.BIN $$(BOOT_ROOT_$1)/boot.scr
BOOT_DEPENDS_$1 := $$(patsubst %, $$(PL_PROJ_$1)/images/linux/%, $$(BOOT_$$(ARCH_$1)))
$$(PL_PROJ_$1): $$(BSP_TARGET_$1)
	-rm -rf $$(PL_PROJ_$1)
	cd $$(BUILD_ROOT_$1) && petalinux-create -t project \
		-s $$(BSP_BUILD_$1)/$$(BSP_PROJECT_$1).bsp -n petalinux_project
	echo 'CONFIG_USER_LAYER_0="'$(CURDIR)/boot/meta-pynq'"' >> $$(PL_CONFIG_$1)
	echo 'CONFIG_SUBSYSTEM_ROOTFS_EXT4=y' >> $$(PL_CONFIG_$1)
	echo 'CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk0p2"' >> $$(PL_CONFIG_$1)
	echo 'CONFIG_SUBSYSTEM_ETHERNET_MANUAL_SELECT=y' >> $$(PL_CONFIG_$1)
	if [ $$(FPGA_MANAGER_$1) = 1 ]; then \
		echo 'CONFIG_SUBSYSTEM_DEVICETREE_FLAGS="-@"' >> $$(PL_CONFIG_$1) ;\
		echo 'CONFIG_SUBSYSTEM_DTB_OVERLAY=y' >> $$(PL_CONFIG_$1) ;\
		echo 'CONFIG_SUBSYSTEM_FPGA_MANAGER=y' >> $$(PL_CONFIG_$1) ;\
	else \
		echo 'CONFIG_SUBSYSTEM_REMOVE_PL_DTB=y' >> $$(PL_CONFIG_$1) ;\
	fi
	echo 'CONFIG_xrt=y' >> $$(PL_ROOTFS_CONFIG_$1)
	echo 'CONFIG_xrt-dev=y' >> $$(PL_ROOTFS_CONFIG_$1)
	echo 'CONFIG_zocl=y' >> $$(PL_ROOTFS_CONFIG_$1)
	echo 'CONFIG_opencl-headers-dev=y' >> $$(PL_ROOTFS_CONFIG_$1)
	echo 'CONFIG_opencl-clhpp-dev=y' >> $$(PL_ROOTFS_CONFIG_$1)
	petalinux-config --silentconfig -p $$(PL_PROJ_$1)

$$(BOOT_ROOT_$1)/BOOT.BIN : $$(BOOT_DEPENDS_$1) $$(BOOT_BITSTREAM_$1) | $$(BOOT_ROOT_$1)
	cd $$(BOOT_ROOT_$1) && petalinux-package --boot --fpga $$(BITSTREAM_ABS_$1) --u-boot -p $$(PL_PROJ_$1) --force
	cp -f $$(PL_PROJ_$1)/images/linux/BOOT.BIN $$(BOOT_ROOT_$1)

$$(BOOT_ROOT_$1)/image.ub : $$(BUILD_ROOT_$1)/image.its $$(BUILD_ROOT_$1)/system.dtb $$(BUILD_ROOT_$1)/$$(KERNEL_$$(ARCH_$1)) | $$(BOOT_ROOT_$1)
	cd $$(BOOT_ROOT_$1) && mkimage -f $$(BUILD_ROOT_$1)/image.its $$@

$$(BOOT_ROOT_$1)/boot.scr : $$(BOOT_DEPENDS_$1) | $$(BOOT_ROOT_$1)
	mkimage -c none -A arm -T script -d \
		$$(PL_PROJ_$1)/project-spec/meta-user/recipes-bsp/u-boot/u-boot-zynq-scr/boot.cmd.default \
		$$(PL_PROJ_$1)/images/linux/boot.scr && \
	cp -f $$(PL_PROJ_$1)/images/linux/boot.scr $$@

$$(BUILD_ROOT_$1)/image.its: $$(CURDIR)/boot/image_$$(ARCH_$1).its | $$(BUILD_ROOT_$1)
	cp $$< $$@

$$(PL_CONFIG_$1): | $$(BSP_BUILD_$1) $$(PL_PROJ_$1)

$$(PL_PROJ_$1)/images/linux/%_fsbl.elf: $$(PL_CONFIG_$1)
	$$(PL_ENV_$1) petalinux-build -c bootloader -p $$(PL_PROJ_$1)

$$(PL_PROJ_$1)/images/linux/u-boot.elf: $$(PL_CONFIG_$1)
	$$(PL_ENV_$1) petalinux-build -c u-boot -p $$(PL_PROJ_$1)

$$(PL_PROJ_$1)/images/linux/$$(KERNEL_$$(ARCH_$1)): $$(PL_CONFIG_$1)
	$$(PL_ENV_$1) petalinux-build -c kernel -p $$(PL_PROJ_$1)

$$(PL_PROJ_$1)/images/linux/system.dtb:  $$(PL_CONFIG_$1)
	$$(PL_ENV_$1) petalinux-build -c device-tree -p $$(PL_PROJ_$1)

$$(PL_PROJ_$1)/images/linux/pmufw.elf:  $$(PL_CONFIG_$1)
	$$(PL_ENV_$1) petalinux-build -c pmufw -p $$(PL_PROJ_$1)

$$(PL_PROJ_$1)/images/linux/bl31.elf:  $$(PL_CONFIG_$1)
	$$(PL_ENV_$1) petalinux-build -c arm-trusted-firmware -p $$(PL_PROJ_$1)

$$(MODULES_$1): $$(PL_PROJ_$1)/images/linux/$$(KERNEL_$$(ARCH_$1))
	cp -f $$(PL_PROJ_$1)/build/tmp/deploy/images/*/modules--*.tgz \
	$$(MODULES_$1)

$$(KERNEL_RPM_$1): $$(PL_CONFIG_$1)
	$$(PL_ENV_$1) petalinux-build -c kernel-devsrc -p $$(PL_PROJ_$1)
	cp -f $$(PL_PROJ_$1)/build/tmp/deploy/rpm/*/kernel-devsrc-1.0-r0.*.rpm \
	$$(KERNEL_RPM_$1)

$$(BUILD_ROOT_$1)/% : $$(PL_PROJ_$1)/images/linux/%
	cp $$< $$@

$$(BUILD_ROOT_$1):
	mkdir -p $$@

$$(BOOT_ROOT_$1):
	mkdir -p $$@

BASE_$1 ?= $$(UBUNTU_RELEASE).$$(ARCH_$1).$$(VERSION).tar.gz
ifeq ($$(PREBUILT),)
	BASE_PATH_$1 := $$(IMAGE_ROOT)/$$(BASE_$1)
else
	BASE_PATH_$1 := $$(PREBUILT)
endif
STAGE4_DEPENDS_$1 := $$(foreach package, $$(STAGE4_PACKAGES_$1), $$(PACKAGE_BUILD_$$(package)_$1) $$(PACKAGE_BUILD_$$(package)))
STAGING_$1 := $$(BUILD_ROOT)/$$(UBUNTU_RELEASE).$1

$$(ROOT_$1) : $$(BASE_PATH_$1) $$(STAGE4_DEPENDS_$1) $$(MODULES_$1) $$(KERNEL_RPM_$1) | $$(CCACHEDIR)
	sudo rm -fr $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	(cd $$(STAGING_$1) && sudo tar -xf $$(realpath $$<))
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/install_packages.sh $$(STAGING_$1) $$(STAGE4_PACKAGES_$1)
	mkdir -p $$(BUILD_ROOT_$1)/modules
	cd $$(BUILD_ROOT_$1)/modules && tar -xf $$(MODULES_$1)
	sudo cp -r --no-preserve=ownership $$(BUILD_ROOT_$1)/modules/* $$(STAGING_$1)
	rm -rf $$(BUILD_ROOT_$1)/modules
	sudo mount -o bind /dev $$(STAGING_$1)/dev
	rpm2cpio $$(KERNEL_RPM_$1) | sudo chroot $$(STAGING_$1) cpio -id
	sudo chroot $$(STAGING_$1) depmod -a $$(LINUX_VERSION)
	sudo umount -l $$(STAGING_$1)/dev
	rm -rf $$(EXTRA_BOOT_$1)
	cp -r $$(STAGING_$1)/boot $$(EXTRA_BOOT_$1)
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)


$$(IMAGE_$1) : $$(ROOT_$1) $$(BOOT_FILES_$1)
	sudo rm -rf $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	cp $$(BOOT_FILES_$1) $$(STAGING_$1)
	(cd $$(PL_PROJ_$1) && petalinux-package --wic --images-dir "$$(STAGING_$1)" --bootfiles "$$(notdir $$(BOOT_FILES_$1))" -c $$< --outdir $$(IMAGE_ROOT) --wks  $$(CURDIR)/boot/image.wks --extra-bootfiles "$$(EXTRA_BOOT_$1)/*:.") && mv $$(IMAGE_ROOT)/petalinux-sdimage.wic $$@


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

endef

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
PACKAGE_ENV_$1 := QEMU_EXE=$$(QEMU_$1) PYNQ_BOARD=Unknown ARCH=$1
DIST_$1 := $$(DIST_ROOT)/$1

$$(STAGE2_$1) : $$(STAGE1_$1) $$(STAGE2_DEPENDS_$1)
	sudo rm -rf $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	(cd $$(STAGING_$1) && sudo tar -xf $$<)
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/install_packages.sh $$(STAGING_$1) $$(STAGE2_PACKAGES_$1)
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)

$$(BASE_$1) : $$(STAGE2_$1) $$(STAGE3_DEPENDS_$1) | $$(IMAGE_ROOT)
	sudo rm -rf $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	(cd $$(STAGING_$1) && sudo tar -xf $$<)
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/install_packages.sh $$(STAGING_$1) $$(STAGE3_PACKAGES_$1)
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)

$$(STAGE1_$1): $$(CONFIG_$1)/multistrap.config | $$(BUILD_ROOT) $$(CCACHEDIR)
	sudo rm -rf $$(STAGING_$1)
	mkdir $$(STAGING_$1)
	$$(PACKAGE_ENV_$1) $$(SCRIPT_DIR)/create_rootfs.sh $$(STAGING_$1) $$(CONFIG_$1)
	(cd $$(STAGING_$1) && sudo tar -cz * > $$@)

qemu_check_$1:
	$$(QEMU_$1) -version | fgrep ${QEMU_VERSION}

$$(DIST_$1): $$(BASE_PATH_$1) | $$(DIST_ROOT)
	mkdir -p $$@
	cp -rf $$(BUILD_ROOT)/PYNQ/dist/*.tar.gz $$@

dist_$1: $$(DIST_$1)

.PHONY: qemu_check_$1 dist_$1

endef

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
	vivado -version | fgrep ${KERNEL_VERSION}
	vitis -version | fgrep ${KERNEL_VERSION}
	which petalinux-config
	which arm-linux-gnueabihf-gcc
	which microblaze-xilinx-elf-gcc
	which ct-ng
	bash $(SCRIPT_DIR)/check_env.sh

boot_files: checkenv $(BOOT_FILES)

images: checkenv $(IMAGE_FILES)

nocheck_images: $(IMAGE_FILES)

real_all: checkenv $(BOOT_FILES) $(IMAGE_FILES) $(DIST_FILES)

sdx_sw: $(patsubst %, sdx_sw_%, $(BOARDS))

sysroot: $(patsubst %, sysroot_%, $(BOARDS))

bsp: $(patsubst %, bsp_%, $(BOARDS))

dist: $(patsubst %, dist_%, $(USED_ARCH))

# Default package clean target
PACKAGE_CLEAN_%: ;

clean: $(PACKAGE_CLEAN)
	-rm -rf $(BUILD_ROOT)
	-rm -rf $(IMAGE_ROOT)

.PHONY: dist bsp boot_files images all clean \
	real_all checkenv sdx_sw sysroot nocheck_images
