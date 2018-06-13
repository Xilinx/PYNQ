USB_SOURCEDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
USB_WORKDIR := ${BUILD_ROOT}/usbgadget

${USB_WORKDIR}: | ${BUILD_ROOT}
	mkdir ${USB_WORKDIR}

${USB_WORKDIR}/staging: | ${USB_WORKDIR}
	mkdir ${USB_WORKDIR}/staging

${USB_WORKDIR}/fatfs: | ${USB_WORKDIR}/staging
	-rm -f ${USB_WORKDIR}/fatfs
	truncate --size 50M ${USB_WORKDIR}/fatfs
	mkfs -t fat -n "PYNQ-USB" ${USB_WORKDIR}/fatfs
	sudo mount ${USB_WORKDIR}/fatfs ${USB_WORKDIR}/staging
	sudo cp -rf ${USB_SOURCEDIR}/fatfs/* ${USB_WORKDIR}/staging
	sudo umount ${USB_WORKDIR}/staging

PACKAGE_BUILD_usbgadget += ${USB_WORKDIR}/fatfs

