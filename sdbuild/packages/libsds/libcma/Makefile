CMA_ARCH ?= $(shell getconf LONG_BIT)
INSTALL_LIB = libcma.so.$(CMA_ARCH)

CC := sdscc
CFLAGS := -mno-bitstream -mno-boot-files -fPIC -target-os linux -shared
CFLAGS += -static-sds
# Use built-in platforms for each architecture 
CFLAGS_32 := -sds-pf zc702
CFLAGS_64 := -sds-pf zcu102

all: libcma.so.32 libcma.so.64

ifeq ($(REBUILD),1)
libcma.so.%: pynqlib.c
	$(CC) $(CFLAGS) $(CFLAGS_$*)  $< -o $@
.PHONY: libcma.so.32 libcma.so.64
endif
install: $(INSTALL_LIB)
	install $< $(DESTDIR)/usr/lib/libcma.so
	install libxlnk_cma.h $(DESTDIR)/usr/include

clean:
	rm -rf *.bit .Xil _sds
