# Makefile to build select Microblaze projects.


BIN_LOGICTOOLS_CONTROLLER = logictools_arduino.bin

all: logictools_controller_bins
	@echo
	@tput setaf 2 ; echo "Completed Microblaze Projects' Builds"; tput sgr0;
	@echo

logictools_controller_bins: $(BIN_LOGICTOOLS_CONTROLLER)
	@cp */Debug/*.bin .

%.bin: FORCE
	cd $(subst .bin,,$@)/Debug && make clean && make 

clean:
	rm -f */Debug/*.bin
	rm -f */Debug/*.elf
	rm -f */Debug/*.elf.size
	rm -f */Debug/src/*.o
	rm -f */Debug/src/*.d
	rm -rf .Xil .metadata SDK.log	

cleanall: clean
	rm -f *.bin

FORCE:
