################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include src/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
ELFSIZE += \
arduino_joystick.elf.size \


# All Target
all: arduino_joystick.elf secondary-outputs

# Tool invocations
arduino_joystick.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../bsp_iop_arduino/iop_arduino_mb/lib -mlittle-endian -mcpu=v10.0 -mxl-soft-mul -Wl,--no-relax -o "arduino_joystick.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

arduino_joystick.elf.size: arduino_joystick.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size arduino_joystick.elf  |tee "arduino_joystick.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

arduino_joystick.bin: arduino_joystick.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary arduino_joystick.elf arduino_joystick.bin
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) arduino_joystick.elf arduino_joystick.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) arduino_joystick.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets

