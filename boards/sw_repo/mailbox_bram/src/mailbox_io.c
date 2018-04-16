/******************************************************************************
 *  Copyright (c) 2018, Xilinx, Inc.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file mailbox_io.c
 *
 * Source file for mailbox IO for PYNQ Microblaze.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  po  02/08/18 release
 *
 * </pre>
 *
 *****************************************************************************/
#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <xil_io.h>
#include <stdio.h>
#include <fcntl.h>

#include <intrgpio.h>
#include <xparameters.h>

#ifdef XPAR_INTRGPIO_NUM_INSTANCES
#include "mailbox_io.h"
#endif

#define STDIN_OFFSET 0xF000
#define STDOUT_OFFSET 0xF400
#define RPCIN_OFFSET 0xF800
#define RPCOUT_OFFSET 0xFC00
#define IO_SIZE 0x400

#define MAX_DESCRIPTOR 10

typedef struct descriptor {
	void* base_addr;
	int size;
	int flags;
} descriptor_t;

static descriptor_t descriptors[MAX_DESCRIPTOR] = {
	{(void*) STDIN_OFFSET, IO_SIZE - 8, O_RDONLY},
	{(void*) STDOUT_OFFSET, IO_SIZE - 8, O_WRONLY},
	{(void*) RPCIN_OFFSET, IO_SIZE - 8, O_RDONLY},
	{(void*) RPCOUT_OFFSET, IO_SIZE - 8, O_WRONLY}
};

__attribute__((weak))
void _handle_events() {

} 

// Status == CTRL - 1
/* void outbyte(char c) {
	while (*stdout_ctrl == WRAP_ADD(*stdout_status, 1)) {
		// Spin until buffer space
	}
	stdout_buffer[*stdout_status] = c;
	*stdout_status = WRAP_ADD(*stdout_status, 1);

}*/

/*char inbyte(void) {
	while (*stdin_ctrl == *stdin_status) {
		// Spin until data available
	}
	char ret = stdin_buffer[*stdin_status];
	*stdin_status = WRAP_ADD(*stdin_status, 1);
	return ret;
}*/

static void volatile_cpy(volatile char* dest, volatile char* src, int len) {
	while (len-- > 0) {
		*dest++ = *src++;
	}
}

int mailbox_available(int file) {
	if (file < 0 || file >= MAX_DESCRIPTOR ||
			descriptors[file].base_addr == NULL) {
		errno = EBADF;
		return -1;
	}
	volatile int32_t* ctrl = (volatile int32_t*)descriptors[file].base_addr;
	volatile int32_t* status = ctrl + 1;
	int buf_size = descriptors[file].size;
	int available = 0;
	int read_stream = descriptors[file].flags == O_RDONLY;

	// The BRAM can produce rubbish when a read/write collision happens
	// so read twice to make sure that the available data if valid.
	int last_available = 0xFFFF;
	while (last_available != available) {
		last_available = available;
		if (read_stream) {
			available = *ctrl - *status;
		} else {
			available = *status - *ctrl - 1;
		}
		if (available < 0) available += buf_size;
	}
	return available;
}

ssize_t mailbox_write(int file, const void* ptr, size_t len) {
	if (file < 0 || file >= MAX_DESCRIPTOR ||
		    descriptors[file].flags != O_WRONLY ||
		    descriptors[file].base_addr == NULL) {
		errno = EBADF;
		return -1;
	}
	volatile int32_t* ctrl = (volatile int32_t*)descriptors[file].base_addr;
	volatile int32_t* status = ctrl + 1;
	volatile char* buffer = (volatile char*)(status + 1);
	int buf_size = descriptors[file].size;

	int available = mailbox_available(file);
	while (available == 0) {
		available = mailbox_available(file);
		_handle_events();
	}
	int write_ptr = *ctrl;
	int to_write = (int)len < available? (int)len : available;
	int first_block = 
		to_write < (buf_size - write_ptr)? to_write: buf_size - write_ptr;
	volatile_cpy(buffer + write_ptr, (char*)ptr, first_block);
	if (first_block < to_write) {
		volatile_cpy(buffer, (char*)ptr + first_block, to_write - first_block);
	}
	write_ptr += to_write;
	if (write_ptr >= buf_size) write_ptr -= buf_size;
	*ctrl = write_ptr;
        if (file == STDOUT_FILENO) {
#ifdef XPAR_INTRGPIO_NUM_INSTANCES
        	IntrGpio_RaiseInterrupt(0);
#endif
	}
	return to_write;
}

ssize_t mailbox_read(int file, void* ptr, size_t len) {
	if (file < 0 || file >= MAX_DESCRIPTOR || 
			descriptors[file].flags != O_RDONLY || 
			descriptors[file].base_addr == NULL) {
		errno = EBADF;
		return -1;
	}
	volatile int32_t* ctrl = (volatile int32_t*)descriptors[file].base_addr;
	volatile int32_t* status = ctrl + 1;
	volatile char* buffer = (volatile char*)(status + 1);
	int buf_size = descriptors[file].size;

	int available = mailbox_available(file);
	// Spin waiting for at least one byte to be available
	while (available == 0) {
		available = mailbox_available(file);
		_handle_events();
	}
	int read_ptr = *status;
	int to_read = (int)len < available? (int)len : available;
	int first_block =
		to_read < (buf_size - read_ptr)? to_read: buf_size - read_ptr;
	volatile_cpy((char*)ptr, buffer + read_ptr, first_block);
	if (first_block < to_read) {
		volatile_cpy((char*)ptr + first_block, buffer, to_read - first_block);
	}
	read_ptr += to_read;
	if (read_ptr >= buf_size) read_ptr -= buf_size;
	*status = read_ptr;
	return to_read;
}

int mailbox_open(const char* pathname, int flags, ...) {
	// Find open descriptor
	int desc = 0;
	while (desc < MAX_DESCRIPTOR && descriptors[desc].base_addr) {
		++desc;
	}
	if (desc == MAX_DESCRIPTOR) {
		errno = ENFILE;
		return -1;
	}
	descriptors[desc].base_addr = (void*)pathname;
	descriptors[desc].flags = flags;
	descriptors[desc].size = 0x7F8;
	return desc;
}

int mailbox_close(int fd) {
	descriptors[fd].base_addr = 0;
	return 0;
}


void mailbox_outbyte(intptr_t device __attribute__((unused)), char c) {
	mailbox_write(1, &c, 1);
}

char mailbox_inbyte(intptr_t device __attribute__((unused))) {
	char c;
	mailbox_read(0, &c, 1);
	return c;
}

off_t mailbox_lseek(int fd __attribute__((unused)),
		off_t offset __attribute__((unused)),
		int whence __attribute__((unused))) {
	return ESPIPE;
}

// Wrapper functions to overload the standard library ones

ssize_t write(int file, const void* ptr, size_t len) {
	return mailbox_write(file, ptr, len);
}

ssize_t read(int file, void* ptr, size_t len) {
	return mailbox_read(file, ptr, len);
}

off_t lseek(int fd __attribute__((unused)),
		off_t offset __attribute__((unused)),
		int whence __attribute__((unused))) {
	return ESPIPE;
}

int open(const char* pathname, int flags, ...) {
	return mailbox_open(pathname, flags);
}

int close(int fd) {
	return mailbox_close(fd);
}
