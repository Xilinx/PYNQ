makefileDir := $(dir $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))

UBOOT_MAKE_ARGS ?= CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm -j4
LINUX_MAKE_ARGS ?= ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- UIMAGE_LOADADDR=2080000 -j4
BOOT_BITSTREAM ?= ${WORKDIR}/PYNQ/boards/${BOARD}/base/base.bit

DTC_REPO := https://github.com/Xilinx/device-tree-xlnx.git
DTC_COMMIT := 11f81055d1afad67398fa5ef443b32be8bc74433

export BOARD_PART
export PS_CONFIG_TCL
export BOARD_CONSTRAINTS

SOURCEDIR := ${makefileDir}

BOOT_FILES := ${OUTDIR}/devicetree.dtb ${OUTDIR}/uImage ${OUTDIR}/BOOT.bin ${OUTDIR}/uEnv.txt

KERNEL_DEB := ${WORKDIR}/linux-headers-4.6.0-xilinx.deb

${KERNEL_DEB}: ${WORKDIR}/linux/.config
	-rm ${WORKDIR}/*.deb
	cd ${WORKDIR}/linux && make ${LINUX_MAKE_ARGS} deb-pkg
	mv ${WORKDIR}/linux-headers* ${WORKDIR}/linux-headers-4.6.0-xilinx.deb
	mv ${WORKDIR}/linux-image* ${WORKDIR}/linux-image-4.6.0-xilinx.deb

${OUTDIR}/devicetree.dtb: ${WORKDIR}/pynq_dts/system.dts ${WORKDIR}/pynq_dts/board.dtsi | ${OUTDIR}
	cd ${WORKDIR}/pynq_dts && bash ${SOURCEDIR}/compile_dtc.sh > $@

${WORKDIR}/pynq_dts/board.dtsi: ${BOARD_DTSI}
	cp $< $@

${WORKDIR}/pynq_dts/system.dts: ${WORKDIR}/pynq.hdf | ${WORKDIR}/device-tree-xlnx
	cd ${WORKDIR} && hsi -mode batch -source ${SOURCEDIR}/create_zynq_devicetree.tcl

${WORKDIR}/pynq.hdf:
	cd ${WORKDIR} && vivado -mode batch -source ${SOURCEDIR}/create_zynq_hdf.tcl

${WORKDIR}/device-tree-xlnx:
	git_clone_checkout ${DTC_REPO} ${DTC_COMMIT} ${WORKDIR}/device-tree-xlnx

${WORKDIR}/linux:
	git_clone_checkout ${LINUX_REPO} ${LINUX_COMMIT} ${WORKDIR}/linux

${WORKDIR}/linux/.config: ${LINUX_CONFIG} | ${WORKDIR}/linux
	cp $< $@

${WORKDIR}/linux/arch/arm/boot/uImage: ${WORKDIR}/linux/.config
	cd ${WORKDIR}/linux && make ${LINUX_MAKE_ARGS} uImage

${OUTDIR}/uImage: ${WORKDIR}/linux/arch/arm/boot/uImage | ${OUTDIR}
	cp $< $@

${OUTDIR}/BOOT.bin: ${SOURCEDIR}/zynq.bif ${WORKDIR}/fsbl.elf ${WORKDIR}/u-boot.elf ${WORKDIR}/bitstream.bit | ${OUTDIR}
	cd ${WORKDIR} && bootgen -image ${SOURCEDIR}/zynq.bif -o ${OUTDIR}/BOOT.bin -w

${WORKDIR}/fsbl.elf: ${WORKDIR}/fsbl/executable.elf
	cp $< $@

${WORKDIR}/fsbl/executable.elf: ${WORKDIR}/pynq.hdf
	cd ${WORKDIR} && hsi -mode batch -source ${SOURCEDIR}/create_zynq_fsbl.tcl

${WORKDIR}/u-boot.elf: ${WORKDIR}/u-boot/u-boot
	cp $< $@

${WORKDIR}/u-boot:
	git_clone_checkout ${UBOOT_REPO} ${UBOOT_COMMIT} ${WORKDIR}/u-boot

${WORKDIR}/u-boot/u-boot: ${WORKDIR}/u-boot/.config
	cd ${WORKDIR}/u-boot && make ${UBOOT_MAKE_ARGS} u-boot

${WORKDIR}/u-boot/.config: ${UBOOT_CONFIG} | ${WORKDIR}/u-boot
	cp $< $@

${WORKDIR}/bitstream.bit: ${BOOT_BITSTREAM} 
	cp $< $@

${BOOT_BITSTREAM}: ${PYNQ_UPDATE} |${WORKDIR}/PYNQ

${OUTDIR}/uEnv.txt: ${SOURCEDIR}/zynq-uEnv.txt | ${OUTDIR}
	cp $< $@
