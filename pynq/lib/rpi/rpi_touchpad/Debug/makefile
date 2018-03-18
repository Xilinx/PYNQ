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
rpi_touchpad.elf.size \


# All Target
all: rpi_touchpad.elf secondary-outputs

# Tool invocations
rpi_touchpad.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../bsp_iop_rpi/iop_rpi_mb/lib -mlittle-endian -mcpu=v10.0 -mxl-soft-mul -Wl,--no-relax -o "rpi_touchpad.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

rpi_touchpad.elf.size: rpi_touchpad.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size rpi_touchpad.elf  |tee "rpi_touchpad.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

rpi_touchpad.bin: rpi_touchpad.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary rpi_touchpad.elf rpi_touchpad.bin
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) rpi_touchpad.elf rpi_touchpad.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) rpi_touchpad.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
