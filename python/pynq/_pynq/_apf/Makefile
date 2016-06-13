CC = arm-linux-gnueabihf-gcc
CPP = arm-linux-gnueabihf-g++

OBJS = dmadefs.o dma.o
LIBS = -l pthread libsds_lib.a
INC = -I include/

all:	
	$(CPP) -fPIC $(INC)  -Wall -O3 -D __SDSOC__ -c dmadefs.c
	$(CPP) -fPIC $(INC)  -Wall -O3 -D __SDSOC__ -c dma.c
	$(CPP) -shared -fPIC -rdynamic $(OBJS)  -Wl,--start-group $(LIBS) -Wl,--end-group -o libdma.so

clean:
	rm *.o *.so -fr
