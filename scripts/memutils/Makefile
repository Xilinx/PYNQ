all:
	gcc -Wall -fPIC  -c utils_xlnk.c -o utils_xlnk.o
	gcc -Wall -fPIC -shared -rdynamic utils_xlnk.o -o utils_xlnk.so
	rm -f *.o

clean:
	rm -f *.so
