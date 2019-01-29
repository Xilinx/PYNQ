/******************************************************************************
*
* Copyright (C) 2018 Xilinx, Inc. All rights reserved.
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
/*****************************************************************************/
/**
*
* @file microblaze_instructions.h
*
* It provides wrapper macros to call 32/64 bit variant of specific
* arithmetic/logical instructions, based on the processor in execution.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who      Date     Changes
* ----- -------- -------- -----------------------------------------------
* 6.8 	mus  	 10/09/18 First release
*
*
* </pre>
*
******************************************************************************/
#ifndef MICROBLAZE_INSTRUCTIONS_H /* prevent circular inclusions */
#define MICROBLAZE_INSTRUCTIONS_H /* by using protection macros */

#if defined (__arch64__)
#define ADDIK addlik
#define ADDK addlk
#define ADDI addli
#define ADD  addl
#define ANDI andli
#define SUBK sublk
#define RSUBK rsublk
#define ORI  orli
#define LI   lli
#define LOAD ll
#define SI   sli
#define STORE sl
#define BRLID brealid
#define BGTID beageid
#define BGEI  beagei
#define BNEID beaneid
#define BLTI  bealti
#define CMPU  cmplu
#define BRID  breaid
#define BNEID beaneid
#define BLEI  bealei
#define BEQI  beaeqi
#define BRI   breai
#else
#define ADDIK addik
#define ADDK  addk
#define ADDI addi
#define ADD  add
#define ANDI andi
#define SUBK subk
#define RSUBK rsubk
#define ORI  ori
#define LI   lwi
#define LOAD lw
#define SI   swi
#define STORE sw
#define BRLID brlid
#define BGTID bgtid
#define BGEI  bgei
#define BNEID bneid
#define BLTI  blti
#define CMPU  cmpu
#define BRID  brid
#define BNEID bneid
#define BLEI  blei
#define BEQI  beqi
#define BRI   bri
#endif

#endif /* MICROBLAZE_INSTRUCTIONS_H */
