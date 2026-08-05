# Makefile to build BSPs.
# NOTE: the historic default XSA (../Pynq-Z1/base/base.xsa) was removed when
# Pynq-Z1/Z2 were deprecated. Callers must supply XSA=... explicitly.
XSA :=

.PHONY: workspace bsp
all: help workspace bsp

help:
	@echo "usage: make [target]"
	@echo
	@echo "arguments:"
	@echo "----------"
	@echo "XSA:     relative/absolute path to the XSA file"
	@echo
	@echo "current configuration:"
	@echo "----------------------"
	@echo "make XSA=$(XSA)"
	@echo

workspace:
	LD_PRELOAD= xsct build_project.tcl $(XSA)

bsp:
	bash build_bsp.sh

clean:
	rm -rf bsp_* hw_build
	rm -rf .Xil .metadata *.log .analytics
