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
arduino_lcd18.elf.size \


# All Target
all: arduino_lcd18.elf secondary-outputs

# Tool invocations
arduino_lcd18.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../bsp_arduino_iop/iop3_mb/lib -mlittle-endian -mcpu=v9.6 -mxl-soft-mul -Wl,--no-relax -o "arduino_lcd18.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

arduino_lcd18.elf.size: arduino_lcd18.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size arduino_lcd18.elf  |tee "arduino_lcd18.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

arduino_lcd18.bin: arduino_lcd18.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary arduino_lcd18.elf arduino_lcd18.bin
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) arduino_lcd18.elf arduino_lcd18.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) arduino_lcd18.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets

