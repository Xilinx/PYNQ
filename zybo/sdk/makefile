# Makefile to build select Microblaze projects.


MBBINS = pmod_adc.bin pmod_dac.bin pmod_oled.bin pmod_als.bin pmod_tmp2.bin \
			pmod_dpot.bin mailbox.bin grove_adc.bin grove_oled.bin \
			grove_imu.bin

all: pmod_bins
	@echo "Completed Microblaze Projects' Builds"

mb_bsp: sdk_workspace
	cd bsp ; make

%.bin: mb_bsp
	cd $(subst .bin,,$@)/Debug; make clean ; make 

pmod_bins: $(MBBINS)
	mkdir -p bins
	@cp */Debug/*.bin bins

sdk_workspace: pmod.hdf
	rm -rf hw_def bsp .metadata/ .Xil/ 
	xsdk -batch -source build_xsdk.tcl

clean:
	rm -f */Debug/*.bin
	rm -f */Debug/*.elf
	rm -f */Debug/*.elf.size
	rm -f */Debug/src/*.o
	rm -f */Debug/src/*.d
	rm -f bins/*
	rm -rf bsp hw_def