################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

C_SRCS += \
../src/ChrFont0.c \
../src/OledChar.c \
../src/OledGrph.c \
../src/pmod_oled.c 

OBJS += \
./src/ChrFont0.o \
./src/OledChar.o \
./src/OledGrph.o \
./src/pmod_oled.o 

C_DEPS += \
./src/ChrFont0.d \
./src/OledChar.d \
./src/OledGrph.d \
./src/pmod_oled.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O1 -g3 -c -fmessage-length=0 -MT"$@" -I../../bsp_pmod/iop1_mb/include -mlittle-endian -mcpu=v9.5 -mxl-soft-mul -Wl,--no-relax -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


