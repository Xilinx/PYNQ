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
/******************************************************************************
 *
 *
 * @file utils.c
 *
 * Implementation of a dynamic array that can only grow in size.
 * The dynamic array is a modified version of:
 * http://stackoverflow.com/questions/3536153/c-dynamically-growing-array
 *
 * Helper function to get the /dev/mem mmap-ed address of a given
 * physical address.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a gn  01/26/16 release
 * 1.00b yrq 08/31/16 add license header
 *
 * </pre>
 *
 *****************************************************************************/

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
 * mmap-ing /dev/mem. Required to use bare-metal drivers on linux. 
 * Return 0 in case of error.
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
unsigned int getVirtualAddress_size(unsigned int phy_addr, 
                                    unsigned int map_size){
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

/*
 * Up to now each of this free is safe to use in combination with 
 * the 'getVirtualAddress' equivalent if and only if:
 * (phy_addr & MAP_MASK) == 0. See @line: 104
 */
void freeVirtualAddress(unsigned int virt_addr){
    munmap((void *)virt_addr, 0x1000);
}
void freeVirtualAddress_size(unsigned int virt_addr, unsigned int map_size){
    munmap((void *)virt_addr, map_size);
}
