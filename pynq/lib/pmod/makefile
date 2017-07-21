# Makefile to build select Microblaze projects.


BIN_PMOD = pmod_adc.bin \
		pmod_dac.bin \
		pmod_oled.bin \
		pmod_als.bin \
		pmod_tc1.bin \
		pmod_tmp2.bin \
		pmod_dpot.bin \
		pmod_timer.bin \
		pmod_pwm.bin \
		pmod_mailbox.bin \
		pmod_grove_adc.bin \
		pmod_grove_oled.bin \
		pmod_grove_imu.bin \
		pmod_grove_buzzer.bin \
		pmod_grove_ledbar.bin \
		pmod_grove_color.bin \
		pmod_grove_dlight.bin \
		pmod_grove_ear_hr.bin \
		pmod_grove_finger_hr.bin \
		pmod_grove_haptic_motor.bin \
		pmod_grove_th02.bin

all: iop_bins
	@echo
	@tput setaf 2 ; echo "Completed Microblaze Projects' Builds"; tput sgr0;
	@echo

iop_bins: $(BIN_PMOD)
	@cp */Debug/*.bin .

%.bin: FORCE
	cd $(subst .bin,,$@)/Debug && make clean && make 

clean:
	rm -f */Debug/*.bin
	rm -f */Debug/*.elf
	rm -f */Debug/*.elf.size
	rm -f */Debug/src/*.o
	rm -f */Debug/src/*.d
	rm -f *.bin
	rm -rf .Xil .metadata SDK.log	

FORCE:
