/******************************************************************************
*
* Copyright (C) 2010 - 2015 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* XILINX CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * - Implementation of a dynamic array that can only grow in size.
 * The dynamic array is a modified version of:
 * http://stackoverflow.com/questions/3536153/c-dynamically-growing-array
 *
 * - Helper function to get the /dev/mem mmap-ed address of a given
 * physical address.
 *
 * - Helper function to get an unsigned integer from a python dictionary
 * given a string as key
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

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
