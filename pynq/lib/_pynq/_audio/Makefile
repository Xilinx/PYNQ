CC = arm-linux-gnueabihf-gcc
CPP = arm-linux-gnueabihf-g++

INC = -I ../inc/

ifeq ($(BOARD),"Pynq-Z1")
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
	$(CC) -fPIC $(INC) -c -g3 -gstabs $(C_SRC)
	$(CPP) -g3 -gstabs -shared -fPIC -rdynamic $(OBJSC) -Wl,--start-group $(LIBS) -Wl,--end-group -o libaudio.so
	rm *.o
