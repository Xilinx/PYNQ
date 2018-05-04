CC = gcc
CPP = g++

INC_SRC = -I ../inc/ 
INC_BSP = -I ../bsp/ps7_cortexa9_0/include/
OBJ := axidma.o xil_io.o

all: $(OBJ)
	$(CC) -g3 -ggdb -shared -fPIC -rdynamic $(OBJ) -Wl,--start-group $(LIBS) -Wl,--end-group -o libdma.so
	rm *.o

axidma.o:
	$(CC) -fPIC $(INC_SRC) $(INC_BSP) -c -g3 -ggdb axidma.c

xil_io.o:
	$(CC) -fPIC $(INC_BSP) -c -g3 -ggdb ../bsp/ps7_cortexa9_0/libsrc/standalone_v6_5/src/xil_io.c

clean:
	rm -f *.o
	rm -f *.so
