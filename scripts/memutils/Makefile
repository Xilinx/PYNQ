all:
	gcc -Wall -fPIC  -c libxlnk_cma.c -o libxlnk_cma.o
	gcc -Wall -fPIC -shared -rdynamic libxlnk_cma.o -o libxlnk_cma.so
	rm -f *.o

clean:
	rm -f *.so

install:
	cp -avf libxlnk_cma.so /usr/lib/
