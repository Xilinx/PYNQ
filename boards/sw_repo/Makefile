# Makefile to build BSPs.
HDF := ../Pynq-Z1/base/base/base.sdk/base.hdf
HW_DEF := hw_base

all: sdk_workspace

sdk_workspace:
	xsdk -batch -source build_xsdk.tcl $(HDF) $(HW_DEF)

clean:
	rm -rf bsp_*
	rm -rf hw_*
	rm -rf .Xil .metadata SDK.log
