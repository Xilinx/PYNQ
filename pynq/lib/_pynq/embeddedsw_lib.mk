EMBEDDEDSW_DIR ?= embeddedsw

# This makefile should be included at the end of a makefile which sets the following
# variables
#
# ESW_LIBS - libraries to include from the embeddedsw repo
# LIB_NAME - name of the output library
# SRC - source files to include in the library
# INC - include directory with the -I prefix

# ARCH := $(shell uname -p)
ARCH := $(shell uname -p)
ESW_SRC := $(filter-out %_g.c, $(foreach lib, $(ESW_LIBS), $(wildcard $(EMBEDDEDSW_DIR)/XilinxProcessorIPLib/drivers/$(lib)/src/*.c)))
ESW_INC := $(patsubst %, -I$(EMBEDDEDSW_DIR)/XilinxProcessorIPLib/drivers/%/src, $(ESW_LIBS))
OS_INC := -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/common -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/common/gcc -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/common
OS_INC_aarch64 := -I$(EMBEDDEDSW_DIR)/lib/bsp/standalone/src/arm/cortexa53/64bit 
COMMON_SRC := $(wildcard common/*.c)
COMMON_SRC_aarch64 := $(wildcard common/aarch64/*.c)
COMMON_INC := -Icommon
COMMON_INC_aarch64 := -Icommon/aarch64

ALL_SRC := $(SRC) $(COMMON_SRC) $(COMMON_SRC_$(ARCH)) $(ESW_SRC)
ALL_INC := $(INC) $(COMMON_INC) $(COMMON_INC_$(ARCH)) $(ESW_INC) $(OS_INC) $(OS_INC_$(ARCH))

all: $(LIB_NAME)

$(LIB_NAME): $(EMBEDDEDSW_DIR)
	gcc -o $(LIB_NAME) -shared -fPIC $(ALL_INC) $(ALL_SRC)
