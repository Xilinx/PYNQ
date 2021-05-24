# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

LOCAL_SRC := $(wildcard src/*.c)
PACKAGE := xrfclk
LIBRARY := lib$(PACKAGE).so
TEST_EXE := test.elf

all:
	gcc -o $(LIBRARY) -shared -fPIC -Isrc $(LOCAL_SRC) -DBOARD_${BOARD} -ggdb

install:
	cp $(LIBRARY) $(PACKAGE)/
	pip3 install .

clean:
	rm -rf $(LIBRARY)
