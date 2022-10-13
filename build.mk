# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

# Builds final pynq source distribution with overlays and BSPs included

VERSION := 3.0.0
SDIST := dist/pynq-$(VERSION).tar.gz

BITS := boards/Pynq-Z1/logictools/logictools.bit \
	boards/Pynq-Z2/logictools/logictools.bit \
	boards/Pynq-Z1/base/base.bit \
	boards/Pynq-Z2/base/base.bit \
	boards/ZCU104/base/base.bit 

LOGICTOOLS_BSP := pynq/lib/logictools/bsp_lcp_ar_mb/lscript.ld
BASE_BSP := pynq/lib/rpi/bsp_iop_rpi/lscript.ld


all: gitsubmodule $(BITS) $(BASE_BSP) $(LOGICTOOLS_BSP) $(SDIST)
	echo "Build completed: $(SDIST)"

gitsubmodule:
	git submodule update

%.bit: %.tcl 
	cd $(dir $@) ; make clean all

$(LOGICTOOLS_BSP): 
	cd boards/sw_repo ; make clean ; make XSA=../Pynq-Z2/logictools/logictools.xsa
	rm -rf boards/sw_repo/*/*/*/*/*/code
	rm -rf boards/sw_repo/*/*/*/*/*/libsrc

	cp -rf boards/sw_repo/bsp_lcp_ar_mb/lcp_ar_mb/standalone_domain/bsp pynq/lib/logictools/bsp_lcp_ar_mb

	cd pynq/lib/logictools && make && make clean
	cd boards/sw_repo && make clean

$(BASE_BSP):
	cd boards/sw_repo ; make clean ; make XSA=../Pynq-Z2/base/base.xsa
	rm -rf boards/sw_repo/*/*/*/*/*/code
	rm -rf boards/sw_repo/*/*/*/*/*/libsrc

	cp -rf boards/sw_repo/bsp_iop_arduino_mb/iop_arduino_mb/standalone_domain/bsp pynq/lib/arduino/bsp_iop_arduino
	cp -rf boards/sw_repo/bsp_iop_pmoda_mb/iop_pmoda_mb/standalone_domain/bsp pynq/lib/pmod/bsp_iop_pmod
	cp -rf boards/sw_repo/bsp_iop_rpi_mb/iop_rpi_mb/standalone_domain/bsp pynq/lib/rpi/bsp_iop_rpi

	cd pynq/lib/arduino && make && make clean
	cd pynq/lib/pmod && make && make clean
	cd boards/sw_repo && make clean

$(SDIST):
	python3 setup.py sdist

clean:
	rm -rf $(BITS) pynq/lib/*/bsp_* $(SDIST)
