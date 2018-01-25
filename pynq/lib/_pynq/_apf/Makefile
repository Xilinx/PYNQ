CC = arm-linux-gnueabihf-gcc
CPP = arm-linux-gnueabihf-g++

INC := ../bsp/ps7_cortexa9_0/include
SRC_DIR1 := ../bsp/ps7_cortexa9_0/libsrc/axidma_v9_1/src/xaxidma.c
SRC_DIR2 := ../bsp/ps7_cortexa9_0/libsrc/standalone_v5_4/src/xil_io.c
OBJ1 := xaxidma.o
OBJ2 := xil_io.o

all:
	$(CC) -fPIC -c $(SRC_DIR1) -I $(INC) -o $(OBJ1)
	$(CC) -fPIC -c $(SRC_DIR2) -I $(INC) -o $(OBJ2)
	$(CC) -g3 -gstabs -shared -fPIC -rdynamic $(OBJ1) $(OBJ2) -Wl,--start-group $(LIBS) -Wl,--end-group -o libdma.so
	rm *.o

clean:
	rm -f *.o
	rm -f *.so