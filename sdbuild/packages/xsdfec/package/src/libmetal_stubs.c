/*
 * Copyright (c) 2019, Xilinx, Inc.
 * All rights reserved.

 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:

 * 1.  Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.

 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.

 * 3.  Neither the name of the copyright holder nor the names of its
 *     contributors may be used to endorse or promote products derived from
 *     this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
