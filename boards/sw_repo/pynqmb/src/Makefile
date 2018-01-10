COMPILER:=mb-gcc
ARCHIVER:=mb-ar
CP=cp
COMPILER_FLAGS=
LIB=libxil.a
EXTRA_ARCHIVE_FLAGS=rc

RELEASEDIR=../../../lib
INCLUDEDIR=../../../include
INCLUDES=-I./. -I${INCLUDEDIR}

PYNQMB_DIR = .
OUTS = *.o

PYNQMB_SRCS := $(wildcard *.c)
PYNQMB_OBJS = $(addprefix $(PYNQMB_DIR)/, $(PYNQMB_SRCS:%.c=%.o))

INCLUDEFILES=$(PYNQMB_DIR)/*.h

libs: libpynqmb.a

libpynqmb.a: print_msg_pynqmb $(PYNQMB_OBJS)
	$(ARCHIVER) $(EXTRA_ARCHIVE_FLAGS) ${RELEASEDIR}/${LIB} ${PYNQMB_OBJS}

print_msg_pynqmb:
	@echo "Compiling pynqmb library"

.PHONY: include
include: libpynqmb_includes

libpynqmb_includes:
	${CP} ${INCLUDEFILES} ${INCLUDEDIR}

clean:
	rm -rf $(PYNQMB_DIR)/${OUTS}

$(PYNQMB_DIR)/%.o: $(PYNQMB_DIR)/%.c $(INCLUDEFILES)
	$(COMPILER) $(COMPILER_FLAGS) $(EXTRA_COMPILER_FLAGS) $(INCLUDES) -c $< -o $@