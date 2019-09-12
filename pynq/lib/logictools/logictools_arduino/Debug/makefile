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
logictools_arduino.elf.size \


# All Target
all: logictools_arduino.elf secondary-outputs

# Tool invocations
logictools_arduino.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-gc-sections -Wl,-T -Wl,../src/lscript.ld -L../../bsp_lcp_ar_mb/lcp_ar_mb/lib -mlittle-endian -mcpu=v11.0 -mxl-soft-mul -Wl,--no-relax -o "logictools_arduino.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

logictools_arduino.elf.size: logictools_arduino.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size logictools_arduino.elf  |tee "logictools_arduino.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

logictools_arduino.bin: logictools_arduino.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary logictools_arduino.elf logictools_arduino.bin
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) logictools_arduino.elf logictools_arduino.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) logictools_arduino.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
