ARCH := $(shell getconf LONG_BIT)
SDSLIB := libsds_lib_$(ARCH).a

all: libsds_lib.so libsds_internal.so
.PHONY: all

libsds_lib.so: wrapper.c libsds_internal.so
	gcc wrapper.c -fPIC -shared -rdynamic -o libsds_lib.so -lpthread -ldl -L. -lsds_internal

libsds_internal.so: $(SDSLIB)
	gcc -shared -rdynamic -o libsds_internal.so -Wl,--whole-archive $(SDSLIB) -Wl,--no-whole-archive

clean:
	-rm -f *.so

install: libsds_lib.so libsds_internal.so libxlnk_cma.h
	cp -avf libsds_lib.so /usr/lib/
	cp -avf libsds_internal.so /usr/lib/
	cp -arvf libxlnk_cma.h /usr/include/
