# Makefile to build select Microblaze projects.


MBBINS = pmod_adc.bin \
		pmod_dac.bin \
		pmod_oled.bin \
		pmod_als.bin \
		pmod_tc1.bin \
		pmod_tmp2.bin \
		pmod_dpot.bin \
		pmod_timer.bin \
		pmod_pwm.bin \
		mailbox.bin \
		pmod_grove_adc.bin \
		pmod_grove_oled.bin \
		pmod_grove_imu.bin \
		pmod_grove_buzzer.bin \
		pmod_grove_ledbar.bin \
		arduino_analog.bin \
		arduino_grove_adc.bin \
		arduino_grove_oled.bin \
		arduino_grove_imu.bin \
		arduino_grove_buzzer.bin \
		arduino_grove_ledbar.bin \
		pmod_grove_color.bin \
		arduino_grove_color.bin \
		pmod_grove_dlight.bin \
		arduino_grove_dlight.bin \
		pmod_grove_ear_hr.bin \
		arduino_grove_ear_hr.bin \
		pmod_grove_finger_hr.bin \
		arduino_grove_finger_hr.bin \
		pmod_grove_haptic_motor.bin \
		arduino_grove_haptic_motor.bin \
		pmod_grove_th02.bin \
		arduino_grove_th02.bin \
		arduino_lcd18.bin

all: iop_bins
	@echo "Completed Microblaze Projects' Builds"

mb_bsp: sdk_workspace
	cd bsp_pmod && make && cd ..
	cd bsp_arduino && make && cd ..

%.bin: mb_bsp
	cd $(subst .bin,,$@)/Debug && make clean && make 

iop_bins: $(MBBINS)
	@cp */Debug/*.bin ./bin/


sdk_workspace: base.hdf 
	xsdk -batch -source build_xsdk.tcl

clean:
	rm -f */Debug/*.bin
	rm -f */Debug/*.elf
	rm -f */Debug/*.elf.size
	rm -f */Debug/src/*.o
	rm -f */Debug/src/*.d
	rm -f bin/*
	rm -rf bsp_pmod bsp_arduino hw_def .Xil .metadata SDK.log	
	rm -rf sdk_import
