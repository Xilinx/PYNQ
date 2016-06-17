CC = arm-linux-gnueabihf-gcc
CPP = arm-linux-gnueabihf-g++

OBJS = devreg.o portinfo.o 
LIBS = -l pthread libsds_lib.a
INC = -I include/

all:	
	$(CC) -fPIC $(INC) -c devreg.c
	$(CC) -fPIC $(INC) -c portinfo.c
	$(CC) -shared -fPIC -rdynamic $(OBJS)  -Wl,--start-group $(LIBS) -Wl,--end-group -o libdma.so
	rm *.o
clean:
	rm *.o *.so -r
