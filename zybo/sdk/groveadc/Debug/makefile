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
groveadc.elf.size \


# All Target
all: groveadc.elf secondary-outputs

# Tool invocations
groveadc.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../standalone_bsp_mb1/mb_1_microblaze_1/lib -mlittle-endian -mcpu=v9.5 -mxl-soft-mul -Wl,--no-relax -o "groveadc.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

groveadc.elf.size: groveadc.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size groveadc.elf  |tee "groveadc.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

groveadc.bin: groveadc.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary groveadc.elf groveadc.bin
	@echo 'Finished building: $@'
	@echo ' '



# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) groveadc.elf groveadc.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) groveadc.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
