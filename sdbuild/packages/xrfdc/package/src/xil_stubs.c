// Copyright (C) 2021-2022 Xilinx, Inc
// Copyright (C) 2022-2026 Advanced Micro Devices, Inc.
// SPDX-License-Identifier: BSD-3-Clause

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

void xil_printf(const char* format, ...) {
	va_list args;
	va_start (args, format);
	vprintf (format, args);
	va_end (args);
}

unsigned int Xil_AssertStatus;

void Xil_Assert(const char* file, int line) {
	printf("Assertion failed at %s:%d\n", file, line);
	exit(1);
}

unsigned char XGetCoreId(void) { return 0; }
unsigned int Xil_IsSpinLockEnabled(void) { return 0; }
unsigned int Xil_SpinLock(void) { return 0; }
unsigned int Xil_SpinUnlock(void) { return 0; }
