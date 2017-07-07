CC = arm-linux-gnueabihf-gcc
CPP = arm-linux-gnueabihf-g++

OBJSC = audio.o 
INC = -I ../inc/

all:	
	$(CC) -fPIC $(INC) -c -g3 -gstabs audio.cpp
	$(CPP) -g3 -gstabs -shared -fPIC -rdynamic $(OBJSC)  -Wl,--start-group $(LIBS) -Wl,--end-group -o libaudio.so
	rm *.o
