################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

C_SRCS += \
../src/ChrFont0.c \
../src/FillPat.c \
../src/OledChar.c \
../src/OledGrph.c \
../src/pmodoled.c 

OBJS += \
./src/ChrFont0.o \
./src/FillPat.o \
./src/OledChar.o \
./src/OledGrph.o \
./src/pmodoled.o 

C_DEPS += \
./src/ChrFont0.d \
./src/FillPat.d \
./src/OledChar.d \
./src/OledGrph.d \
./src/pmodoled.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -I../../standalone_bsp_mb1/mb_1_microblaze_1/include -mlittle-endian -mcpu=v9.5 -mxl-soft-mul -Wl,--no-relax -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


