# Copyright (C) 2021 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause

EMBEDDEDSW_DIR ?= embeddedsw

# This makefile should be included at the end of a makefile which sets the following
# variables
#
# ESW_LIBS - libraries to include from the embeddedsw repo
# LIB_NAME - name of the output library
# SRC - source files to include in the library
# INC - include directory with the -I prefix

PYNQ_BUILD_ARCH ?= $(shell uname -p)
ESW_SRC := $(filter-out %_g.c, $(foreach lib, $(ESW_LIBS), $(wildcard $(EMBEDDEDSW_DIR)/XilinxProcessorIPLib/drivers/$(lib)/src/*.c)))
ESW_INC := $(patsubst %, -I$(EMBEDDEDSW_DIR)/XilinxProcessorIPLib/drivers/%/src, $(ESW_LIBS))
OS_INC := -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/common -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/common/gcc -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/common
OS_INC_aarch64 := -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/ARMv8/64bit/
OS_INC_aarch64 += -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/ARMv8/64bit/platform/ZynqMP/
OS_INC_armv7l := -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/cortexa9/
COMMON_SRC := $(wildcard common/*.c)
COMMON_SRC_aarch64 := $(wildcard common/aarch64/*.c)
COMMON_SRC_armv7l := $(wildcard common/armv7l/*.c)
COMMON_INC := -Icommon
COMMON_INC_aarch64 := -Icommon/aarch64
COMMON_INC_armv7l := -Icommon/armv7l

ALL_SRC := $(SRC) $(COMMON_SRC) $(COMMON_SRC_$(PYNQ_BUILD_ARCH)) $(ESW_SRC)
ALL_INC := $(INC) $(COMMON_INC) $(COMMON_INC_$(PYNQ_BUILD_ARCH)) $(ESW_INC) $(OS_INC) $(OS_INC_$(PYNQ_BUILD_ARCH))

# Per-library object directory (so _xhdmi's .o files never collide with
# _pcam5c's when both libraries live alongside each other).
OBJ_DIR := $(LIB_NAME:.so=).objs
ALL_OBJ := $(patsubst %.c,$(OBJ_DIR)/%.o,$(ALL_SRC))

all: $(LIB_NAME)

$(LIB_NAME): $(EMBEDDEDSW_DIR) $(ALL_OBJ)
	$(CC) -shared -fPIC -o $(LIB_NAME) $(ALL_OBJ) $(LDFLAGS)

# Compile each translation unit into its own object file. Under
# qemu-user-static cc1 also crashes intermittently on individual files
# (not deterministic, not always the same file). A 3-attempt retry loop
# absorbs these transient emulation failures without slowing down the
# happy path. Per-file (rather than one giant cc invocation) keeps each
# cc1 short enough that restarting it is cheap.
$(OBJ_DIR)/%.o: %.c | $(OBJ_DIR)
	@mkdir -p $(dir $@)
	@for attempt in 1 2 3; do \
	    $(CC) -fPIC $(ALL_INC) $(CFLAGS) -c $< -o $@ && break || \
	    { echo "cc attempt $$attempt failed for $<"; sleep 1; }; \
	done; \
	test -f $@

$(OBJ_DIR):
	mkdir -p $@
