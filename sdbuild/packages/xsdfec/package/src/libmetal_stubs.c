/*
 * Copyright (c) 2019, Xilinx, Inc.
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>

#include <metal/sys.h>
#include <metal/io.h>
#include <metal/log.h>

struct metal_state _metal;

void metal_default_log_handler(enum metal_log_level level,
			       const char *format, ...)
{
	char msg[1024];
	va_list args;
	static const char *level_strs[] = {
		"metal: emergency: ",
		"metal: alert:     ",
		"metal: critical:  ",
		"metal: error:     ",
		"metal: warning:   ",
		"metal: notice:    ",
		"metal: info:      ",
		"metal: debug:     ",
	};

	va_start(args, format);
	vsnprintf(msg, sizeof(msg), format, args);
	va_end(args);

	if (level <= _metal.common.log_level){
    	    printf("%s%s", level_strs[level], msg);
	}
}

void metal_io_init(struct metal_io_region *io, void *virt,
	      const metal_phys_addr_t *physmap, size_t size,
	      unsigned page_shift, unsigned int mem_flags,
	      const struct metal_io_ops *ops)
{
	const struct metal_io_ops nops = {NULL, NULL, NULL, NULL, NULL, NULL};

	io->virt = virt;
	io->physmap = physmap;
	io->size = size;
	io->page_shift = page_shift;
	if (page_shift >= sizeof(io->page_mask) * CHAR_BIT)
		/* avoid overflow */
		io->page_mask = -1UL;
	else
		io->page_mask = (1UL << page_shift) - 1UL;
	io->mem_flags = mem_flags;
	io->ops = ops ? *ops : nops;
}

__attribute__((constructor)) void foo(void) {
    _metal.common.log_level = METAL_LOG_WARNING;
    _metal.common.log_handler = metal_default_log_handler;
}

