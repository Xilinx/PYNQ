/******************************************************************************
*
* Copyright (C) 2010 - 2017 Xilinx, Inc.  All rights reserved.
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
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
#ifndef _XDEBUG_H
#define _XDEBUG_H

#if defined(DEBUG) && !defined(NDEBUG)

#include <stdio.h>

#ifndef XDEBUG_WARNING
#define XDEBUG_WARNING
#warning DEBUG is enabled
#endif

#define XDBG_DEBUG_ERROR             0x00000001    /* error  condition messages */
#define XDBG_DEBUG_GENERAL           0x00000002    /* general debug  messages */
#define XDBG_DEBUG_ALL               0xFFFFFFFF    /* all debugging data */

#define XDBG_DEBUG_FIFO_REG          0x00000100    /* display register reads/writes */
#define XDBG_DEBUG_FIFO_RX           0x00000101    /* receive debug messages */
#define XDBG_DEBUG_FIFO_TX           0x00000102    /* transmit debug messages */
#define XDBG_DEBUG_FIFO_ALL          0x0000010F    /* all fifo debug messages */

#define XDBG_DEBUG_TEMAC_REG         0x00000400    /* display register reads/writes */
#define XDBG_DEBUG_TEMAC_RX          0x00000401    /* receive debug messages */
#define XDBG_DEBUG_TEMAC_TX          0x00000402    /* transmit debug messages */
#define XDBG_DEBUG_TEMAC_ALL         0x0000040F    /* all temac  debug messages */

#define XDBG_DEBUG_TEMAC_ADPT_RX     0x00000800    /* receive debug messages */
#define XDBG_DEBUG_TEMAC_ADPT_TX     0x00000801    /* transmit debug messages */
#define XDBG_DEBUG_TEMAC_ADPT_IOCTL  0x00000802    /* ioctl debug messages */
#define XDBG_DEBUG_TEMAC_ADPT_MISC   0x00000803    /* debug msg for other routines */
#define XDBG_DEBUG_TEMAC_ADPT_ALL    0x0000080F    /* all temac adapter debug messages */

#define xdbg_current_types (XDBG_DEBUG_ERROR)

#define xdbg_stmnt(x)  x

/* In VxWorks, if _WRS_GNU_VAR_MACROS is defined, special syntax is needed for
 * macros that accept variable number of arguments
 */
#if defined(XENV_VXWORKS) && defined(_WRS_GNU_VAR_MACROS)
#define xdbg_printf(type, args...) (((type) & xdbg_current_types) ? printf (## args) : 0)

#else /* ANSI Syntax */

#define xdbg_printf(type, ...) (((type) & xdbg_current_types) ? printf (__VA_ARGS__) : 0)

#endif

#else /* defined(DEBUG) && !defined(NDEBUG) */

#define xdbg_stmnt(x)

/* See VxWorks comments above */
#if defined(XENV_VXWORKS) && defined(_WRS_GNU_VAR_MACROS)
#define xdbg_printf(type, args...)
#else /* ANSI Syntax */
#define xdbg_printf(...)
#endif

#endif /* defined(DEBUG) && !defined(NDEBUG) */

#endif /* _XDEBUG_H */
