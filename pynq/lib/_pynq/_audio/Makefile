CC = gcc
CPP = g++

INC_SRC = -I ../inc/ 
INC_BSP = -I ../bsp/ps7_cortexa9_0/include/

ifeq ($(BOARD), Pynq-Z1)
C_SRC += audio_direct.cpp
OBJSC += audio_direct.o
else
C_SRC += audio_adau1761.cpp \
../src/i2cps.c \
../src/uio.c
OBJSC += audio_adau1761.o \
i2cps.o \
uio.o
endif

all:	
	$(CC) -fPIC $(INC_SRC) $(INC_BSP) -c -g3 -ggdb $(C_SRC)
	$(CPP) -g3 -ggdb -shared -fPIC -rdynamic $(OBJSC) -Wl,--start-group $(LIBS) -Wl,--end-group -o libaudio.so
	rm *.o
