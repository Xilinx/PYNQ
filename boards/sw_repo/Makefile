# Makefile to build BSPs.
XSA := ../Pynq-Z1/base/base.xsa

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
	xsct build_project.tcl $(XSA)

bsp:
	bash build_bsp.sh

clean:
	rm -rf bsp_* hw_build
	rm -rf .Xil .metadata *.log .analytics
