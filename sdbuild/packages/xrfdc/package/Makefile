# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

EMBEDDEDSW_DIR ?= embeddedsw
PACKAGE := xrfdc
ESW_LIBS := rfdc scugic
LIBRARY := lib$(PACKAGE).so
ESW_VERSION  := xilinx-v2020.2
LIB_METAL_DIR := $(EMBEDDEDSW_DIR)/ThirdParty/sw_services/libmetal/src/libmetal
LIB_METAL_INC := $(LIB_METAL_DIR)/build-libmetal/lib/include
ESW_SRC := $(filter-out %_g.c, $(foreach lib, $(ESW_LIBS), $(wildcard $(EMBEDDEDSW_DIR)/XilinxProcessorIPLib/drivers/$(lib)/src/*.c)))
ESW_INC := $(patsubst %, -I$(EMBEDDEDSW_DIR)/XilinxProcessorIPLib/drivers/%/src, $(ESW_LIBS))
OS_INC := -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/common
OS_INC += -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/ARMv8/64bit
OS_INC += -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/common/gcc
OS_INC += -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/common
OS_INC += -I$(LIB_METAL_INC)
LOCAL_SRC := $(wildcard src/*.c)

all: $(LIBRARY)

$(LIBRARY): $(EMBEDDEDSW_DIR) $(LIB_METAL_INC)
	gcc -o $(LIBRARY) -shared -fPIC $(ESW_INC) \
		-Isrc $(ESW_SRC) $(LOCAL_SRC) $(OS_INC) -D__BAREMETAL__ -ggdb

install:
	cp $(LIBRARY) $(PACKAGE)/
	pip3 install .

$(EMBEDDEDSW_DIR):
	git clone https://github.com/Xilinx/embeddedsw \
		--depth 1 -b $(ESW_VERSION) $(EMBEDDEDSW_DIR)

$(LIB_METAL_INC): $(EMBEDDED_DIR)
	mkdir -p $(LIB_METAL_DIR)/build-libmetal;
	cd $(LIB_METAL_DIR)/build-libmetal; \
	cmake .. -Wno-deprecated \
		-DCMAKE_TOOLCHAIN_FILE=/../../../../../../../toolchain.cmake
