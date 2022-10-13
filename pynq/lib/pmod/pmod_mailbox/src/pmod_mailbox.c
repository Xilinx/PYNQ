/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  SPDX-License-Identifier: BSD-3-Clause
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file pmod_mailbox.c
 *
 * IOP code (MicroBlaze) for mailbox.
 * The mailbox can be used to transfer data between Python and microblaze 
 * processors. This includes both read and write.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  04/13/16 release
 * 1.00b pp  05/27/16 fix pmod_init()
 * 1.5     yrq 05/16/17 separate pmod and arduino
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "xil_types.h"
#include "xil_io.h"

#define XPAR_PMOD_IO_SWITCH_BASEADDR XPAR_MB_1_MB1_SWITCH_S00_AXI_BASEADDR

// command from A9 to MB0
#define MAILBOX_CMD_ADDR (*(volatile unsigned *)(0x0000FFFC))
// address of MB0
#define MAILBOX_ADDR (*(volatile unsigned *)(0x0000FFF8))
#define MAILBOX_DATA(x) (*(volatile unsigned *)(0x0000FF00+((x)*4)))
/* Command format
 *  bit[0] : MP issued command when 1
 *  bit[2:1] : Data width => 00 : byte (8 bits)
 *                           01 : half-word (16 bits)
 *                           1x : word (32 bits)
 *  bit[3] : Read/Write   => 0 :  Python requests write
 *                           1 : Python requests read
 *  bit[15:8] : Data size=>  0 : invalid 
 *                           1 : single read/write (use for register)
 *                           others : multiple read/write (use for buffer)
 *
 * Examples:
 *      Byte write- 0x00000m01 => m being count ranging from 1 to 253
 *      Byte read- 0x00000m09
 *      Half-word write- 0x00000m03
 *      Half-word read- 0x00000m0B
 *      Word write- 0x00000m07
 *      Word read- 0x00000m0F
 */

int main (void)
{
    int cmd, count, i;

    while(1){
        while((MAILBOX_CMD_ADDR & 0x01)==0);
        cmd=MAILBOX_CMD_ADDR;
        
        count = (cmd & 0x0000ff00) >> 8;
        if((count==0) || (count>253)) {
            // clear bit[0] to indicate cmd processed,
            // set rest to 1s to indicate error in cmd word
            MAILBOX_CMD_ADDR = 0xfffffffe;
            return -1;
        }
        for(i=0; i<count; i++) {
            if (cmd & 0x08) // Python issues read
            {
                switch ((cmd & 0x06) >> 1) { // use bit[2:1]
                    case 0 : MAILBOX_DATA(i) = *(u8 *) MAILBOX_ADDR; break;
                    case 1 : MAILBOX_DATA(i) = *(u16 *) MAILBOX_ADDR; break;
                    case 2 : break;
                    case 3 : MAILBOX_DATA(i) = *(u32 *) MAILBOX_ADDR; break;
                }
            }
            else // Python issues write
            {
                switch ((cmd & 0x06) >> 1) { // use bit[2:1]
                case 0 : *(u8 *)MAILBOX_ADDR = (u8 *) MAILBOX_DATA(i); break;
                case 1 : *(u16 *)MAILBOX_ADDR = (u16 *) MAILBOX_DATA(i); break;
                case 2 : break;
                case 3 : *(u32 *)MAILBOX_ADDR = (u32 *)MAILBOX_DATA(i); break;
                }
            }

        }
        MAILBOX_CMD_ADDR = 0x0;
    }
    return 0;
}

