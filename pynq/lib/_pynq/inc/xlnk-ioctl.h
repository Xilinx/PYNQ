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
 * @file xlnk-ioctl.h
 *
 * Libraries for xlnk driver.
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
 
#ifndef _XLNK_IOCTL_H
#define _XLNK_IOCTL_H

#include <linux/ioctl.h>

#define XLNK_IOC_MAGIC 'X'

#define XLNK_IOCRESET       _IO(XLNK_IOC_MAGIC, 0)

#define XLNK_IOCALLOCBUF    _IOWR(XLNK_IOC_MAGIC, 2, unsigned long)
#define XLNK_IOCFREEBUF     _IOWR(XLNK_IOC_MAGIC, 3, unsigned long)
#define XLNK_IOCADDDMABUF   _IOWR(XLNK_IOC_MAGIC, 4, unsigned long)
#define XLNK_IOCCLEARDMABUF _IOWR(XLNK_IOC_MAGIC, 5, unsigned long)

#define XLNK_IOCDMAREQUEST  _IOWR(XLNK_IOC_MAGIC, 7, unsigned long)
#define XLNK_IOCDMASUBMIT   _IOWR(XLNK_IOC_MAGIC, 8, unsigned long)
#define XLNK_IOCDMAWAIT     _IOWR(XLNK_IOC_MAGIC, 9, unsigned long)
#define XLNK_IOCDMARELEASE  _IOWR(XLNK_IOC_MAGIC, 10, unsigned long)





#define XLNK_IOCDEVREGISTER _IOWR(XLNK_IOC_MAGIC, 16, unsigned long)
#define XLNK_IOCDMAREGISTER _IOWR(XLNK_IOC_MAGIC, 17, unsigned long)
#define XLNK_IOCDEVUNREGISTER   _IOWR(XLNK_IOC_MAGIC, 18, unsigned long)
#define XLNK_IOCCDMAREQUEST _IOWR(XLNK_IOC_MAGIC, 19, unsigned long)
#define XLNK_IOCCDMASUBMIT  _IOWR(XLNK_IOC_MAGIC, 20, unsigned long)
#define XLNK_IOCMCDMAREGISTER   _IOWR(XLNK_IOC_MAGIC, 23, unsigned long)
#define XLNK_IOCCACHECTRL   _IOWR(XLNK_IOC_MAGIC, 24, unsigned long)

#define XLNK_IOCSHUTDOWN    _IOWR(XLNK_IOC_MAGIC, 100, unsigned long)
#define XLNK_IOCRECRES      _IOWR(XLNK_IOC_MAGIC, 101, unsigned long)

#define XLNK_IOC_MAXNR      101

#endif
