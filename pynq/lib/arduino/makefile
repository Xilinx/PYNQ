# Makefile to build select Microblaze projects.


MBBINS =  	arduino_analog.bin \
		arduino_grove_adc.bin \
		arduino_grove_oled.bin \
		arduino_grove_imu.bin \
		arduino_grove_buzzer.bin \
		arduino_grove_ledbar.bin \
		arduino_grove_color.bin \
		arduino_grove_dlight.bin \
		arduino_grove_ear_hr.bin \
		arduino_grove_finger_hr.bin \
		arduino_grove_haptic_motor.bin \
		arduino_grove_th02.bin \
		arduino_lcd18.bin \
		arduino_mailbox.bin

all: arduino_bins
	@echo "Completed Microblaze Projects' Builds"

%.bin: FORCE 
	cd $(subst .bin,,$@)/Debug && make clean && make 

arduino_bins: $(MBBINS)
	@cp */Debug/*.bin .

clean:
	rm -f */Debug/*.bin
	rm -f */Debug/*.elf
	rm -f */Debug/*.elf.size
	rm -f */Debug/src/*.o
	rm -f */Debug/src/*.d
	rm -f *.bin
	rm -rf .Xil .metadata SDK.log	

FORCE:
