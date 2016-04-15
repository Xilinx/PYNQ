# Makefile to build select Microblaze projects.


MBBINS = pmod_adc.bin pmod_dac.bin pmod_oled.bin pmod_als.bin pmod_tmp2.bin \
			pmod_dpot.bin mailbox.bin grove_adc.bin grove_oled.bin \
			grove_imu.bin

all: pmod_bins
	@echo "Completed Microblaze Projects' Builds"

mb_bsp: 
	cd standalone_bsp_mb1 ; make

%.bin: mb_bsp
	cd $(subst .bin,,$@)/Debug; make clean ; make 

pmod_bins: $(MBBINS)
	mkdir -p bins
	@cp */Debug/*.bin bins


clean:
	rm -f */Debug/*.bin
	rm -f bins/*