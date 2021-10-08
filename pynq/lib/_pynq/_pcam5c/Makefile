# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

CFLAGS += -U__linux__ -ggdb

export ESW_LIBS := iicps iic gpio scugic axivdma mipicsiss csi dphy
export ESW_LIBS +=  video_common

export LIB_NAME := _pcam5c/libpcam5c.so

export SRC := $(patsubst %, _pcam5c/%, $(wildcard *.c))

all:
	make -C .. -f embeddedsw_lib.mk

clean:
	rm -rf *.o *.so
