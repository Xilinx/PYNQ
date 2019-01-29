# Makefile to build BSPs.
HDF := ../Pynq-Z1/base/base/base.sdk/base.hdf
HW_DEF := hw_base

all: help sdk_workspace

help:
	@echo "usage: make [target]"
	@echo
	@echo "arguments:"
	@echo "----------"
	@echo "HDF:    relative/absolute path to the HDF file"
	@echo "HW_DEF: name of the hardware project"
	@echo
	@echo "current configuration:"
	@echo "----------------------"
	@echo "make HDF=$(HDF)"
	@echo "     HW_DEF=$(HW_DEF)"
	@echo

sdk_workspace:
	xsdk -batch -source build_xsdk.tcl $(HDF) $(HW_DEF)

clean:
	rm -rf bsp_*
	rm -rf hw_*
	rm -rf .Xil .metadata SDK.log
