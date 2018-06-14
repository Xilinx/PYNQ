export ESW_LIBS := iic
export LIB_NAME := _xiic/libiic.so

export SRC := $(patsubst %, _xiic/%, $(wildcard *.c))

all:
	make -C .. -f embeddedsw_lib.mk
