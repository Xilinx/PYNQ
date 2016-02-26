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
pmodals.elf.size \


# All Target
all: pmodals.elf secondary-outputs

# Tool invocations
pmodals.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../standalone_bsp_mb1/mb_1_microblaze_1/lib -mlittle-endian -mcpu=v9.5 -mxl-soft-mul -Wl,--no-relax -o "pmodals.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

pmodals.elf.size: pmodals.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size pmodals.elf  |tee "pmodals.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

pmodals.bin: pmodals.elf
	@echo 'Invoking: MicroBlaze Bin Gen'
	mb-objcopy -O binary pmodals.elf pmodals.bin
	@echo 'Finished building: $@'
	@echo ' '



# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) pmodals.elf pmodals.bin
	-@echo ' '

secondary-outputs: $(ELFSIZE) pmodals.bin

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
