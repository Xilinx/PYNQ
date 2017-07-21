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
logictools_controller.elf.size \


# All Target
all: logictools_controller.elf secondary-outputs

# Tool invocations
logictools_controller.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../bsp_logictools_controller/lcp_lcp_mb_mb/lib -mlittle-endian -mcpu=v9.6 -mxl-soft-mul -Wl,--no-relax -o "logictools_controller.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

logictools_controller.elf.size: logictools_controller.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size logictools_controller.elf  |tee "logictools_controller.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

logictools_controller.bin: logictools_controller.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary logictools_controller.elf logictools_controller.bin
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) logictools_controller.elf logictools_controller.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) logictools_controller.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets