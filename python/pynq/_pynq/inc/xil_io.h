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
* @file xil_io.h
*
* This file contains the interface for the general IO component, which
* encapsulates the Input/Output functions for processors that do not
* require any special I/O handling.
*
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who      Date     Changes
* ----- -------- -------- -----------------------------------------------
* 1.00a ecm/sdm  10/24/09 First release
* 1.00a sdm      07/21/10 Added Xil_Htonl/s, Xil_Ntohl/s
* 3.07a asa	     08/31/12 Added xil_printf.h include
* 3.08a sgd	     11/05/12 Reverted SYNC macros definitions
* 
* </pre>
* 
******************************************************************************/

#ifndef XIL_IO_H           /* prevent circular inclusions */
#define XIL_IO_H           /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xil_types.h"
//#include "xpseudo_asm.h"
//#include "xil_printf.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

#if defined __GNUC__
#  define SYNCHRONIZE_IO	dmb()
#  define INST_SYNC		isb()
#  define DATA_SYNC		dsb()
#else
#  define SYNCHRONIZE_IO
#  define INST_SYNC
#  define DATA_SYNC
#endif /* __GNUC__ */

/*****************************************************************************/
/**
*
* Perform an big-endian input operation for a 16-bit memory location
* by reading from the specified address and returning the Value read from
* that address.
*
* @param	Addr contains the address to perform the input operation at.
*
* @return	The Value read from the specified input address with the
*		proper endianness. The return Value has the same endianness
*		as that of the processor, i.e. if the processor is
*		little-engian, the return Value is the byte-swapped Value read
*		from the address.
*
* @note		None.
*
******************************************************************************/
#define Xil_In16LE(Addr) Xil_In16((Addr))

/*****************************************************************************/
/**
*
* Perform a big-endian input operation for a 32-bit memory location
* by reading from the specified address and returning the Value read from
* that address.
*
* @param	Addr contains the address to perform the input operation at.
*
* @return	The Value read from the specified input address with the
*		proper endianness. The return Value has the same endianness
*		as that of the processor, i.e. if the processor is
*		little-engian, the return Value is the byte-swapped Value read
*		from the address.
*
*
* @note		None.
*
******************************************************************************/
#define Xil_In32LE(Addr) Xil_In32((Addr))

/*****************************************************************************/
/**
*
* Perform a big-endian output operation for a 16-bit memory location
* by writing the specified Value to the specified address.
*
* @param	Addr contains the address to perform the output operation at.
* @param	Value contains the Value to be output at the specified address.
*		The Value has the same endianness as that of the processor.
*		If the processor is little-endian, the byte-swapped Value is
*		written to the address.
*
*
* @return	None
*
* @note		None.
*
******************************************************************************/
#define Xil_Out16LE(Addr, Value) Xil_Out16((Addr), (Value))

/*****************************************************************************/
/**
*
* Perform a big-endian output operation for a 32-bit memory location
* by writing the specified Value to the specified address.
*
* @param	Addr contains the address to perform the output operation at.
* @param	Value contains the Value to be output at the specified address.
*		The Value has the same endianness as that of the processor.
*		If the processor is little-endian, the byte-swapped Value is
*		written to the address.
*
* @return	None
*
* @note		None.
*
******************************************************************************/
#define Xil_Out32LE(Addr, Value) Xil_Out32((Addr), (Value))

/*****************************************************************************/
/**
*
* Convert a 32-bit number from host byte order to network byte order.
*
* @param	Data the 32-bit number to be converted.
*
* @return	The converted 32-bit number in network byte order.
*
* @note		None.
*
******************************************************************************/
#define Xil_Htonl(Data) Xil_EndianSwap32((Data))

/*****************************************************************************/
/**
*
* Convert a 16-bit number from host byte order to network byte order.
*
* @param	Data the 16-bit number to be converted.
*
* @return	The converted 16-bit number in network byte order.
*
* @note		None.
*
******************************************************************************/
#define Xil_Htons(Data) Xil_EndianSwap16((Data))

/*****************************************************************************/
/**
*
* Convert a 32-bit number from network byte order to host byte order.
*
* @param	Data the 32-bit number to be converted.
*
* @return	The converted 32-bit number in host byte order.
*
* @note		None.
*
******************************************************************************/
#define Xil_Ntohl(Data) Xil_EndianSwap32((Data))

/*****************************************************************************/
/**
*
* Convert a 16-bit number from network byte order to host byte order.
*
* @param	Data the 16-bit number to be converted.
*
* @return	The converted 16-bit number in host byte order.
*
* @note		None.
*
******************************************************************************/
#define Xil_Ntohs(Data) Xil_EndianSwap16((Data))

/************************** Function Prototypes ******************************/

/* The following functions allow the software to be transportable across
 * processors which may use memory mapped I/O or I/O which is mapped into a
 * seperate address space.
 */
u8 Xil_In8(INTPTR Addr);
u16 Xil_In16(INTPTR Addr);
u32 Xil_In32(UINTPTR Addr);

void Xil_Out8(INTPTR Addr, u8 Value);
void Xil_Out16(INTPTR Addr, u16 Value);
void Xil_Out32(UINTPTR Addr, u32 Value);


u16 Xil_In16BE(INTPTR Addr);
u32 Xil_In32BE(INTPTR Addr);
void Xil_Out16BE(INTPTR Addr, u16 Value);
void Xil_Out32BE(INTPTR Addr, u32 Value);

u16 Xil_EndianSwap16(u16 Data);
u32 Xil_EndianSwap32(u32 Data);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
