GCC_MB_SOURCEDIR := $(dir $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))


MB_BINUTILS_REPO := https://github.com/Xilinx/binutils.git
MB_BINUTILS_COMMIT := 449520bc2fb858cf802fec6554593f7233763079
GCC_MB_WORKDIR := ${WORKDIR}/gcc-mb
export CT_COMPILE_ROOT = ${GCC_MB_WORKDIR}
export CT_SOURCE_ROOT = ${GCC_MB_SOURCEDIR}

PACKAGE_BUILD += ${GCC_MB_WORKDIR}/microblazeel-xilinx-elf/bin/mb-gcc

${GCC_MB_WORKDIR}/binutils: | ${GCC_MB_WORKDIR}
	git_clone_checkout ${MB_BINUTILS_REPO} ${MB_BINUTILS_COMMIT} ${GCC_MB_WORKDIR}/binutils

${GCC_MB_WORKDIR}/microblazeel-xilinx-elf/bin/mb-gcc: | ${GCC_MB_WORKDIR}/samples ${GCC_MB_WORKDIR}/binutils
	cd ${GCC_MB_WORKDIR} && ${GCC_MB_SOURCEDIR}/build.sh

${GCC_MB_WORKDIR}/samples: | ${GCC_MB_SOURCEDIR}/samples ${GCC_MB_WORKDIR}
	cp -r ${GCC_MB_SOURCEDIR}/samples $@

${GCC_MB_WORKDIR}:
	mkdir -p $@
