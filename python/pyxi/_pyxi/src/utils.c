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
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

#include "utils.h"


void initArray(Array *a, size_t initialSize) {
    a->array = (ptr *)malloc(initialSize * sizeof(ptr));
    a->refCnt = (int *)calloc(initialSize, sizeof(int));
    a->used = 0;
    a->size = initialSize;
}

void appendElemArray(Array *a, ptr elem) {
    if (a->used == a->size) {
      a->size *= 2;
      a->array = (ptr *)realloc(a->array, a->size*sizeof(ptr));
      a->refCnt = (int *)realloc(a->refCnt, a->size*sizeof(int));
    }
    a->array[a->used++] = elem;
    a->refCnt[a->used] = 1;
}

void freeArray(Array *a) {
    free(a->array);
    free(a->refCnt);
    a->array = NULL;
    a->refCnt = NULL;
    a->used = a->size = 0;
}


/*
 * Get the virtual address referencing the physical address resulting from
 * mmap-ing /dev/mem
 * Required to use bare-metal drivers on linux. Return 0 in case of error.
 */
unsigned int getVirtualAddress(unsigned int phy_addr){
    int fd;
    void *map_base;

    if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1)
        return 0;
    const unsigned int MAP_SIZE = 4096UL;
    const unsigned int MAP_MASK = (MAP_SIZE - 1);    
    map_base = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE , MAP_SHARED, fd, 
                    phy_addr & ~MAP_MASK);
    if(map_base == MAP_FAILED)
        return 0;
    return (unsigned int)(((unsigned int)map_base) + (phy_addr & MAP_MASK));
}
unsigned int getVirtualAddress_size(unsigned int phy_addr, unsigned int map_size){
    int fd;
    void *map_base;
    if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1)
        return 0;
    const unsigned int MAP_SIZE = 4096UL;
    const unsigned int MAP_MASK = (MAP_SIZE - 1);    
    map_base = mmap(NULL, map_size, PROT_READ | PROT_WRITE , MAP_SHARED, fd, 
                    phy_addr & ~MAP_MASK);
    if(map_base == MAP_FAILED)
        return 0;
    return (unsigned int)(((unsigned int)map_base) + (phy_addr & MAP_MASK));
}

//WARNING: up to now each of this free is safe to use in combination with 
//the 'getVirtualAddress' equivalent iff (phy_addr & MAP_MASK) == 0. 
//see @line: 104
void freeVirtualAddress(unsigned int virt_addr){
    munmap((void *)virt_addr, 0x1000);
}
void freeVirtualAddress_size(unsigned int virt_addr, unsigned int map_size){
    munmap((void *)virt_addr, map_size);
}
