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
grove_ledbar.elf.size \


# All Target
all: grove_ledbar.elf secondary-outputs

# Tool invocations
grove_ledbar.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../bsp/iop1_mb/lib -mlittle-endian -mcpu=v9.5 -mxl-soft-mul -Wl,--no-relax -o "grove_ledbar.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

grove_ledbar.elf.size: grove_ledbar.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size grove_ledbar.elf  |tee "grove_ledbar.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

grove_ledbar.bin: grove_ledbar.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary grove_ledbar.elf grove_ledbar.bin
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) grove_ledbar.elf grove_ledbar.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) grove_ledbar.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
