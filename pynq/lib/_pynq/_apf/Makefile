all:
	cd axidma_v9_1 && make
	cd standalone_v5_4 && make
	gcc -fPIC -shared -rdynamic  xil_io.o xaxidma.o -o  libdma.so
	rm -f *.o

clean:
	rm -f *.o
	rm -f *.so
