ARCH := $(shell getconf LONG_BIT)

all: libsds_lib.so
.PHONY: all

libsds_lib.so:
	gcc wrapper.c -fPIC -shared -rdynamic -o libsds_lib.so -Wl,--whole-archive libsds_lib_$(ARCH).a -l pthread  -Wl,--no-whole-archive

clean:
	-rm -f *.so

install: libsds_lib.so
	cp -avf libsds_lib.so /usr/lib/
	cp -arvf libxlnk_cma.h /usr/include/
