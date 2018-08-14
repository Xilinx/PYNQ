ARCH := $(shell getconf LONG_BIT)
INSTALL_LIB = libcma.so.$(ARCH)

CC := sdscc
CFLAGS := -mno-bitstream -mno-boot-files -fPIC -target-os linux -shared
# Use built-in platforms for each architecture 
CFLAGS_32 := -sds-pf zc702
CFLAGS_64 := -sds-pf zcu102

all: libcma.so.32 libcma.so.64

libcma.so.%: pynqlib.c
	$(CC) $(CFLAGS) $(CFLAGS_$*)  $< -o $@

install: $(INSTALL_LIB)
	cp -avf $< /usr/lib/libcma.so
	cp -avf libxlnk_cma.h /usr/include
