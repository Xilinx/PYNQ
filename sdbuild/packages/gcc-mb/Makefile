GCC_MB_SOURCEDIR := $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))
GCC_MB_WORKDIR := ${BUILD_ROOT}/gcc-mb
export CT_COMPILE_ROOT = ${GCC_MB_WORKDIR}
export CT_SOURCE_ROOT = ${GCC_MB_SOURCEDIR}

PACKAGE_BUILD_gcc-mb_arm += ${GCC_MB_WORKDIR}/arm/microblazeel-xilinx-elf/bin/mb-gcc
PACKAGE_BUILD_gcc-mb_aarch64 += ${GCC_MB_WORKDIR}/aarch64/microblazeel-xilinx-elf/bin/mb-gcc

SYSROOT_IMAGE_arm := ${BUILD_ROOT}/${UBUNTU_RELEASE}.arm.stage1.img
SYSROOT_IMAGE_aarch64 := ${BUILD_ROOT}/${UBUNTU_RELEASE}.aarch64.stage1.img

PACKAGE_CLEAN_gcc-mb:
	-if [ -e ${GCC_MB_WORKDIR} ]; then chmod u+w -fR ${GCC_MB_WORKDIR}; fi
	-rm -rf ${GCC_MB_WORKDIR}

${GCC_MB_WORKDIR}/%/microblazeel-xilinx-elf/bin/mb-gcc: | ${GCC_MB_WORKDIR}/samples ${GCC_MB_WORKDIR}/patches
	cd ${GCC_MB_WORKDIR} && ${GCC_MB_SOURCEDIR}/build.sh $* $<

${GCC_MB_WORKDIR}/arm/microblazeel-xilinx-elf/bin/mb-gcc: ${SYSROOT_IMAGE_arm}
${GCC_MB_WORKDIR}/aarch64/microblazeel-xilinx-elf/bin/mb-gcc: ${SYSROOT_IMAGE_aarch64}

${GCC_MB_WORKDIR}/samples: | ${GCC_MB_SOURCEDIR}/samples ${GCC_MB_WORKDIR}
	cp -r ${GCC_MB_SOURCEDIR}/samples $@

${GCC_MB_WORKDIR}/patches: | ${GCC_MB_SOURCEDIR}/patches ${GCC_MB_WORKDIR}
	cp -r ${GCC_MB_SOURCEDIR}/patches $@

${GCC_MB_WORKDIR}:
	mkdir -p $@
