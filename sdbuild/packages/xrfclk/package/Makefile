# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

PACKAGE := xrfclk
LIBRARY := lib$(PACKAGE).so
TEST_EXE := test.elf

SRCS:= src/xrfdc_clk_wrapper.c src/xrfdc_lmx2594.c src/xrfdc_sc18is602b.c
SRCS_ZCU111 = src/xrfdc_lmk04208.c
SRCS_RFSoC2x2:= src/xrfdc_lmk04832.c 

SRC_OPTION := ${SRCS} ${SRCS_${BOARD}}

all:
	gcc -o $(LIBRARY) -shared -fPIC -Isrc ${SRC_OPTION} -DBOARD_${BOARD} -ggdb

install:
	cp $(LIBRARY) $(PACKAGE)/
	pip3 install .

clean:
	rm -rf $(LIBRARY)
