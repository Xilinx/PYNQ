/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
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
 
/*****************************************************************************/
/**
 *
 * @file utils.h
 *
 * Implementation of a dynamic array that can only grow in size.
 * The dynamic array is a modified version of:
 * http://stackoverflow.com/questions/3536153/c-dynamically-growing-array
 *
 * Helper function to get the /dev/mem mmap-ed address of a given
 * physical address.
 *
 * Helper function to get an unsigned integer from a python dictionary
 * given a string as key
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who      Date     Changes
 * ----- -------- -------- -----------------------------------------------
 * 1.00a gn       01/24/15 First release
 * 1.00b yrq      08/31/16 Added license header
 * 
 * </pre>

******************************************************************************/

#ifndef __UTILS_H__
#define __UTILS_H__

#include <Python.h>

typedef int *ptr;

typedef struct {
  ptr *array;
  int *refCnt;
  size_t used;
  size_t size;
} Array;

void initArray(Array *a, size_t initialSize);

void appendElemArray(Array *a, ptr elem);

void freeArray(Array *a);


/*
 * Get the virtual address referencing the physical address resulting from
 * mmap-ing /dev/mem
 * Required to use bare-metal drivers on linux. Return NULL in case of error.
 */
unsigned int getVirtualAddress(unsigned int phy_addr);
unsigned int getVirtualAddress_size(unsigned int phy_addr, unsigned int map_size);
void freeVirtualAddress(unsigned int virt_addr);
void freeVirtualAddress_size(unsigned int phy_addr, unsigned int map_size);

/*
 * Return an unsigned integer value from a dictionary, using a string as key.
 * This function assumes correctness of the input dictionary and existence
 * of the key in the dictionary.
 */
#define PyDict_GetUintString(dict,key) \
        ((unsigned int)PyLong_AsUnsignedLong(PyDict_GetItemString(dict, key)))


void *frame_alloc(size_t len);
unsigned int frame_getPhyAddr(void *buf);
void frame_free(void *buf);

#endif // __UTILS_H__
