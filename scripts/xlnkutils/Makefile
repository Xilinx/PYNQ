all:
	gcc -fPIC -shared -rdynamic -o libsds_lib.so -Wl,--whole-archive libsds_lib.a -l pthread  -Wl,--no-whole-archive

clean:
	rm -f *.so

install:
	cp -avf libsds_lib.so /usr/lib/
	cp -arvf libxlnk_cma.h /usr/include/
