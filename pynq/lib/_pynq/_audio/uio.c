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
 * @file uio.c
 *
 * Functions to interact with linux UIO. No safe checks here, so users must
 * know what they are doing.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a yrq 12/05/17 Initial release
 *
 * </pre>
 *
 *****************************************************************************/

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include "uio.h"

/******************************************************************************
 * Function to set the UIO device.
 * @param   uio_index is the uio index in /dev list.
 * @param   length is the length of the MMAP in bytes.
 * @return  A pointer pointing to the MMAP of the UIO.
 *****************************************************************************/
void* setUIO(int uio_index, int length){
    char uio_buf[32];
    int uio_fd;
    void *uio_ptr;

    sprintf(uio_buf, "/dev/uio%d", uio_index);    
    uio_fd = open(uio_buf, O_RDWR);
    if (uio_fd < 1) {
        printf("Invalid UIO device file: %s.\n", uio_buf);
    }
    // mmap the UIO devices
    uio_ptr = mmap(NULL, length, 
                   PROT_READ|PROT_WRITE, MAP_SHARED, uio_fd, 0);
    return uio_ptr;
}

/******************************************************************************
 * Function to set the UIO device.
 * @param   uio_ptr is the uio pointer to be freed.
 * @param   length is the length of the MMAP.
 * @return  0 on success; -1 otherwise.
 *****************************************************************************/
int unsetUIO(void* uio_ptr, int length){
    return munmap(uio_ptr, length);
}