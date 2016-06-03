# Makefile to build select Microblaze projects.


MBBINS = pmod_adc.bin \
	 pmod_dac.bin \
	 pmod_als.bin \
	 pmod_dpot.bin \
	 pmod_oled.bin \


all: pmod_bins
	@echo "Completed Microblaze Projects' Builds"

mb_bsp: sdk_workspace
	cd bsp && make

%.bin: mb_bsp
	cd $(subst .bin,,$@)/Debug && make clean && make 

pmod_bins: $(MBBINS)
	@echo ""
	@echo "+++ To complete delivery of binaries to pynq/pmods folder, please run:"
	@echo "+++ cp */Debug/*.bin ../../python/pynq/pmods"
	@echo ""

sdk_workspace: pmod_arduino.hdf 
	xsdk -batch -source build_xsdk.tcl

clean:
	rm -f */Debug/*.bin
	rm -f */Debug/*.elf
	rm -f */Debug/*.elf.size
	rm -f */Debug/src/*.o
	rm -f */Debug/src/*.d
	rm -f bins/*
	rm -rf bsp hw_def .Xil .metadata SDK.log	
	rm -rf sdk_import