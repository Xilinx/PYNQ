# Makefile to build select Microblaze projects.


MBBINS = pmodadc.bin pmoddac.bin pmodoled.bin pmodals.bin pmodtmp2.bin pmoddpot.bin mailbox.bin

all: pmod_bins
	@echo "Completed Microblaze Projects' Builds"

mb_bsp: standalone_bsp_mb1/mb_1_microblaze_1/lib/libxil.a
	cd standalone_bsp_mb1 ; make

%.bin: mb_bsp
	cd $(subst .bin,,$@)/Debug; make clean ; make 

pmod_bins: $(MBBINS)
	-mkdir pmodbins
	@cp */Debug/*.bin pmodbins


clean:
	rm -f */Debug/*.bin
	rm -f pmodbins/*