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
 * @file arduino.c
 *
 * Code to handle interface switch configuration, configure Pattern, Boolean,
 * FSM, and Trace analyzer engines targeting Arduino interface.
 * Allows pattern generation by loading desired pattern in local BRAM during
 * pattern engine configuration. Similarly, FSM is implemented by loading
 * finite state machine content in its local BRAM.  The Trace analyzer samples
 * desired number of samples of the interface switch's input, output, and tri-
 * state control signals and passes via DDR memory buffer. ALl three engines
 * run at a sample clock frequency which is provided by PS's FCLK_CLK1 source.
 * The sample clock frequency can range from 0.25 MHz to 50 MHz. Due to header
 * pins signal traces on the board having signal integrity problem, the
 * maximum clock frequency run for this application is about 25 MHz.
 * Twenty-four Boolean functions may be implemented, each function of up
 * to five variables.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  11/23/17 release
 * 1.01  yrq 01/27/18 fix for bsp changes and rename
 *
 * </pre>
 *
 *****************************************************************************/
#include "xparameters.h"
#include <stdio.h>
// AXI CDMA is used to move Pattern and FSM data from DDR to Block RAM
#include "xaxicdma.h"
// AXI DMA is used to move tracebuffer data into DDR
#include "xaxidma.h"
#include "xil_cache.h"
#include "xil_io.h"

#define XPAR_TRACE_CNTRL_0_BASEADDR \
	XPAR_LCP_AR_TRACE_ANALYZER_TRACE_CNTRL_64_0_S_AXI_TRACE_CNTRL_BASEADDR
#define XPAR_BOOLEAN_BASEADDR \
    XPAR_LCP_AR_BOOLEAN_GENERATOR_BOOLEAN_GENERATOR_S_AXI_BASEADDR
#define XPAR_FSM_IO_SWITCH_BASEADDR \
    XPAR_LCP_AR_FSM_GENERATOR_FSM_IO_SWITCH_S_AXI_BASEADDR
#define XPAR_CONTROLLERS_REG_BASEADDR \
    XPAR_LCP_AR_CONTROLLERS_REG_BASEADDR
// AP_CTRL Register bits [3:0] ap_ready, ap_idle, ap_done, ap_start
#define TRACE_CNTRL_ADDR_AP_CTRL 0x00
#define TRACE_CNTRL_DATA_COMPARE_LSW 0x10   // bits [31:0]
#define TRACE_CNTRL_DATA_COMPARE_MSW 0x14   // bits [63:32]
#define TRACE_CNTRL_LENGTH  0x1c            // 32-bit
#define TRACE_CNTRL_SAMPLE_RATE  0x24       // 32-bit

//#define BUFFER_BASE 0x02000000
//#define LENGTH 0x10000 // source & destination buffer length in bytes

#define XPAR_FSM_BRAM_RST_ADDR_BASEADDR \
    XPAR_LCP_AR_FSM_GENERATOR_FSM_BRAM_RST_ADDR_BASEADDR
#define PATTERN_CDMA_BRAM_MEMORY 0x30000000 // CDMA access to PATTERN BRAM
// BRAM Port B mapped through 2nd BRAM Controller accessed by CDMA
#define PATTERN_TRI_CDMA_BRAM_MEMORY 0x30040000 // CDMA access to PATTERN TRI
// BRAM Port B mapped through 2nd BRAM Controller accessed by CDMA
#define FSM_CDMA_BRAM_MEMORY 0xC0000000
#define FSM_CDMA_BRAM_MEMORY_SIZE 0x8000    // size in bytes
#define DDR_MEMORY 0x21000000

#define XPAR_CDMA_0_DEVICE_ID XPAR_LCP_AR_AXI_CDMA_0_DEVICE_ID
#define XPAR_AXIDMA_0_DEVICE_ID XPAR_LCP_AR_TRACE_ANALYZER_AXI_DMA_0_DEVICE_ID
#define XPAR_FUNCTION_SEL_BASEADDR \
    XPAR_LCP_AR_GENERATOR_SELECT_FUNCTION_SEL_BASEADDR
#define XPAR_LCP_INTR_BASEADDR XPAR_LCP_AR_INTR_BASEADDR
#define XPAR_NSAMPLES_AND_SINGLE_BASEADDR \
  XPAR_LCP_AR_PATTERN_GENERATOR_PATTERN_NSAMPLES_BASEADDR
// commands and data between A9 to MicroBlaze
#define MAILBOX_CMD_ADDR       (*(volatile u32 *)(0x0000FFFC))
#define MAILBOX_DATA(x)        (*(volatile u32 *)(0x0000F000 +((x)*4)))

/*
 * Commands
 * Configure top-level interface_switch IP with desirable BOOLEAN, PTN, FSM
 * functionality on each header pin
 */
#define INTF_SWITCH_CONFIG      0x1
#define READ_INTF_SWITCH_CONFIG 0xA
// Boolean Generator related command
#define CONFIG_BOOLEAN          0x2
#define READ_BOOLEAN_DIRECTION  0xC
// Pattern Generator related command
#define CONFIG_PATTERN          0x3
/*
 * FSM related command
 * Use TRACE_ONLY command to capture the trace after FSM is running
 */
#define CONFIG_FSM              0x4
// The following command allows to trace data
#define CONFIG_TRACE            0x5
/*
 * The following command will run the armed engines,
 * the four bits [11:8] will indicate the machine
 * [11]:TRACE, [10]:FSM, [9]:PTN, [8]:BOOLEAN
 */
#define RUN                     0xD
/*
 * The following command will stop the indicated machine(s)
 * [11]:TRACE, [10]:FSM, [9]:PTN, [8]:BOOLEAN
 */
#define STOP                    0xE
/*
 * The following command will return status, 1=reset, 2=ready, 4=running
 * The status will be return in MAILBOX_DATA(3):TRACE, MAILBOX_DATA(2):FSM,
 * MAILBOX_DATA(1):PTN, MAILBOX_DATA(0):BOOLEAN
 */
#define CHECK_STATUS            0xF
/*
 * The following command will step the configured, [11:8] indicates engines
 * [11]:TRACE, [10]:FSM, [9]:PTN, [8]:BOOLEAN
 */
#define STEP                    0xB
/*
 * The following command will reset the engine, [11:8] indicates engines
 * [11]:TRACE, [10]:FSM, [9]:PTN, [8]:BOOLEAN
 */
#define RESET                   0x10

// One hot encoding for engine status
#define RESET_STATE 1
#define READY_STATE 2
#define RUN_STATE 4

#define BOOLEAN_ENGINE_BIT      0x100   // BOOLEAN_ENGINE_BIT
#define PATTERN_ENGINE_BIT      0x200   // PATTERN_ENGINE_BIT
#define FSM_ENGINE_BIT          0x400   // FSM_ENGINE_BIT
#define TRACE_ENGINE_BIT        0x800

// Defines running functional units
#define BOOLEAN                     0x1
#define PATTERN                     0x2
#define PATTERN_BOOLEAN             0x3
#define FSM                         0x4
#define FSM_BOOLEAN                 0x5
#define FSM_PATTERN                 0x6
#define FSM_PATTERN_BOOLEAN         0x7
#define TRACE                       0x8
#define TRACE_BOOLEAN               0x9
#define TRACE_PATTERN               0xA
#define TRACE_PATTERN_BOOLEAN       0xB
#define TRACE_FSM                   0xC
#define TRACE_FSM_BOOLEAN           0xD
#define TRACE_FSM_PATTERN           0xE
#define TRACE_FSM_PATTERN_BOOLEAN   0xF

u32 tracing = 0;
int CDMA_Status, Status, i;
int pattern_numofsamples, fsm_numofsamples, trace_numofsamples;
int saved_trace_numofsamples, stop_issued;
int first_step = 0;
u8 * pattern_data_source, * pattern_tri_source, * fsm_source;
u8 * destination, * traceptr;
u32 fsm_direction;
u32 reg0, reg1, reg2, reg3, reg4, reg5, reg6;
u32 cmd, cmd1;

// AXI CDMA related definitions
XAxiCdma xcdma;
XAxiCdma_Config * CdmaCfgPtr;

// AXI DMA related definitions
XAxiDma AxiDma;
XAxiDma_Config *CfgPtr;

u32 pattern_multiple, pattern_status = RESET_STATE;
u32 fsm_status = RESET_STATE, trace_status = RESET_STATE;
u32 msw_compare, lsw_compare;
u32 boolean_status = RESET_STATE;

int pattern_generator_config(void) {
    pattern_multiple = 0;
    pattern_data_source = (u8 *)MAILBOX_DATA(0); // DDR address for the pattern
    pattern_data_source = (u8 *) ((u32) pattern_data_source);
    pattern_numofsamples = MAILBOX_DATA(1); // number of words in the pattern

    // move pattern data from DDR memory to BlockRAM
    destination = (u8 *)PATTERN_CDMA_BRAM_MEMORY;
    XAxiCdma_IntrDisable(&xcdma, XAXICDMA_XR_IRQ_ALL_MASK);
    Xil_DCacheFlushRange((UINTPTR)&pattern_data_source, 
                         pattern_numofsamples*4);
    Status = XAxiCdma_SimpleTransfer(&xcdma, (u32) pattern_data_source, \
            (u32) destination, pattern_numofsamples*4, NULL, NULL);
    if (Status != XST_SUCCESS) {
        CDMA_Status = XAxiCdma_GetError(&xcdma);
        if (CDMA_Status != 0x0) {
            XAxiCdma_Reset(&xcdma);
            return 0xFFFF0003;
        }
    }
    while (XAxiCdma_IsBusy(&xcdma));
    CDMA_Status = XAxiCdma_GetError(&xcdma);
    if (CDMA_Status != 0x0) {
        XAxiCdma_Reset(&xcdma);
        return 0xFFFF0004;
    }
    if(MAILBOX_DATA(2)){
        pattern_multiple = 1;
    }
	pattern_tri_source = (u8 *)MAILBOX_DATA(3);	// Tri control BRAM address
	pattern_tri_source = (u8 *) ((u32) pattern_tri_source);
	// move pattern data from DDR memory to BlockRAM
	destination = (u8 *)PATTERN_TRI_CDMA_BRAM_MEMORY;
	XAxiCdma_IntrDisable(&xcdma, XAXICDMA_XR_IRQ_ALL_MASK);
	Xil_DCacheFlushRange((UINTPTR)&pattern_tri_source, pattern_numofsamples*4);
	Status = XAxiCdma_SimpleTransfer(&xcdma, (u32) pattern_tri_source, \
			(u32) destination, pattern_numofsamples*4, NULL, NULL);
	if (Status != XST_SUCCESS) {
		CDMA_Status = XAxiCdma_GetError(&xcdma);
		if (CDMA_Status != 0x0) {
			XAxiCdma_Reset(&xcdma);
			return 0xFFFF0005;
		}
	}
	while (XAxiCdma_IsBusy(&xcdma));
	CDMA_Status = XAxiCdma_GetError(&xcdma);
	if (CDMA_Status != 0x0) {
		XAxiCdma_Reset(&xcdma);
		return 0xFFFF0006;
	}
    Xil_Out32(XPAR_NSAMPLES_AND_SINGLE_BASEADDR,pattern_numofsamples);
    Xil_Out32(XPAR_NSAMPLES_AND_SINGLE_BASEADDR+8,pattern_multiple);
    pattern_status = READY_STATE;
    return 0;
}

int run_tracebuffer(void) {
    // setup and enable tracebuffer engine components
    XAxiDma_Reset(&AxiDma);
    // Wait for reset to complete
    while(!XAxiDma_ResetIsDone(&AxiDma));
    // Configure Stream DMA controller
    Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) traceptr, \
            trace_numofsamples*8, XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
        Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
        Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
        MAILBOX_DATA(0) = 0xFFFF0008;
        return 1;
    }
    // Setup the trace controller
    // number of samples
    Xil_Out32(XPAR_TRACE_CNTRL_0_BASEADDR+TRACE_CNTRL_LENGTH, \
    		trace_numofsamples);
    Xil_Out32(XPAR_TRACE_CNTRL_0_BASEADDR+TRACE_CNTRL_DATA_COMPARE_MSW,\
            msw_compare); // MS word of trigger mask
    Xil_Out32(XPAR_TRACE_CNTRL_0_BASEADDR+TRACE_CNTRL_DATA_COMPARE_LSW,\
            lsw_compare); // LS word of trigger mask
    // Issue start pulse
    Xil_Out32(XPAR_TRACE_CNTRL_0_BASEADDR+TRACE_CNTRL_ADDR_AP_CTRL,0x1);
    Xil_Out32(XPAR_TRACE_CNTRL_0_BASEADDR+TRACE_CNTRL_ADDR_AP_CTRL,0x0);
    return 0;
}

int main (void) {

    int status, control_read;

    // Set direction register of INTR and set it low
    Xil_Out32(XPAR_LCP_INTR_BASEADDR+4,0x0);
    Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);

    // Setup CDMA Controller
    CdmaCfgPtr = XAxiCdma_LookupConfig(XPAR_CDMA_0_DEVICE_ID);
    if (!CdmaCfgPtr) {
        return XST_FAILURE;
    }

    Status = XAxiCdma_CfgInitialize(&xcdma , CdmaCfgPtr,
            CdmaCfgPtr->BaseAddress);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
        xil_printf("Status = %x\r\n",Status);
    }

    /* Initialize the XAxiDma device.    */
    CfgPtr = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
    if (!CfgPtr) {
        xil_printf("No config found for %d\r\n", XPAR_AXIDMA_0_DEVICE_ID);
        return XST_FAILURE;
    }

    Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
    if (Status != XST_SUCCESS) {
        xil_printf("Initialization failed %d\r\n", Status);
        return XST_FAILURE;
    }

    XAxiDma_Reset(&AxiDma);

    /* Disable interrupts, we use polling mode */
    XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
                        XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
                        XAXIDMA_DMA_TO_DEVICE);

    /*
     * Set all Arduino header pins as unused/input as default by driving
     * tri-state controls to 1 and selecting channel 3 of the interface switch.
     * Channel 3 data_o is connected to logic0 tri_o is connected to logic1
     * and data_i is left open. All Arduino pins have PULL UP in xdc file
     * function select for pins 9:0
     */
    Xil_Out32(XPAR_FUNCTION_SEL_BASEADDR,0xffffffff);
    // function select for pins 19:10
    Xil_Out32(XPAR_FUNCTION_SEL_BASEADDR+8,0xffffffff);

    // Following code configures all CFGLUTs to y=I0 & I1 & I2 & I3 & I4
    for(i=0; i<48; i++)
        Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*i,0x80000000);
    // tristate all outputs
    Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*62,0x00ffffff);
    // program all CFGLUTs
    Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*63,0x00ffffff | 0x80000000);
    Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*63,0x00ffffff);

    // Make all engines in RESET state
    pattern_status = RESET_STATE;
    fsm_status = RESET_STATE;
    trace_status = RESET_STATE;

    first_step = 0;
    // issue stop pulse to PATTERN, Trace, FSM, to make their enables false
    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x06);
    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x04);
    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x12);
    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x10);
    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x0A);
    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x08);
    // Disconnect BOOLEAN output
    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x0);


    while(1) {
        while(MAILBOX_CMD_ADDR == 0); // wait for CMD to be issued
        cmd = MAILBOX_CMD_ADDR;

        switch(cmd & 0xff) {
        case INTF_SWITCH_CONFIG:
            // function select for pins 9:0 and pins 19:10
            Xil_Out32(XPAR_FUNCTION_SEL_BASEADDR,MAILBOX_DATA(0));
            Xil_Out32(XPAR_FUNCTION_SEL_BASEADDR+8,MAILBOX_DATA(1));
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case CONFIG_BOOLEAN:
            for(i=0; i<48; i++)
                Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*i,MAILBOX_DATA(i));
            Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*62,MAILBOX_DATA(62));
            Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*63,\
                    MAILBOX_DATA(63) | 0x80000000);
            Xil_Out32(XPAR_BOOLEAN_BASEADDR+4*63,MAILBOX_DATA(63));
            boolean_status = READY_STATE;
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case READ_BOOLEAN_DIRECTION:
            MAILBOX_DATA(0)=Xil_In32(XPAR_BOOLEAN_BASEADDR+4*62);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case CONFIG_PATTERN:
            status = pattern_generator_config();
            MAILBOX_DATA(0)=status;
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case CONFIG_FSM:
            reg0 = MAILBOX_DATA(0);     // input select for pins 0,1,2,3
            reg1 = MAILBOX_DATA(1);     // input select for pins 4,5,6,7
            reg2 = MAILBOX_DATA(2);     // output select for pins 0,1,2,3
            reg3 = MAILBOX_DATA(3);     // output select for pins 4,5,6,7
            reg4 = MAILBOX_DATA(4);     // output select for pins 8,9,10,11
            reg5 = MAILBOX_DATA(5);     // output select for pins 12,13,14,15
            reg6 = MAILBOX_DATA(6);     // output select for pins 16,17,18,19
            fsm_direction = MAILBOX_DATA(7);    // I/O direction
            fsm_source = (u8 *)MAILBOX_DATA(8); // DDR address for pattern
            fsm_source = (u8 *) ((u32) fsm_source);
            // move pattern data from DDR memory to BlockRAM
            destination = (u8 *)FSM_CDMA_BRAM_MEMORY;
            XAxiCdma_IntrDisable(&xcdma, XAXICDMA_XR_IRQ_ALL_MASK);
            Xil_DCacheFlushRange((UINTPTR)&fsm_source, \
                    FSM_CDMA_BRAM_MEMORY_SIZE);
            Status = XAxiCdma_SimpleTransfer(&xcdma, (u32) fsm_source, \
                    (u32) destination, FSM_CDMA_BRAM_MEMORY_SIZE, NULL, NULL);
            if (Status != XST_SUCCESS) {
                CDMA_Status = XAxiCdma_GetError(&xcdma);
                if (CDMA_Status != 0x0) {
                    XAxiCdma_Reset(&xcdma);
                    Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
                    Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
                    MAILBOX_DATA(0) = 0xFFFF0006;   // return error code
                    break;
                }
            }
            while (XAxiCdma_IsBusy(&xcdma)); // Wait for DMA to complete
            CDMA_Status = XAxiCdma_GetError(&xcdma);
            if (CDMA_Status != 0x0) {
                XAxiCdma_Reset(&xcdma);
                Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
                MAILBOX_DATA(0) = 0xFFFF0007;       // return error code
                break;
            }
            // Setup the FSM
            // configure to either use NS [8:5] or external pin
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR,reg0);
            // configure to use external pins
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR+4,reg1);
            // configure output bits [3:0]
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR+8,reg2);
            // configure output bits [7:4]
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR+0xc,reg3);
            // configure output bits [11:8]
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR+0x10,reg4);
            // configure output bits [15:12]
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR+0x14,reg5);
            // configure output bits [19:16]
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR+0x18,reg6);
            // configure direction for all 20 header pins
            Xil_Out32(XPAR_FSM_IO_SWITCH_BASEADDR+0x1c,fsm_direction);
            // Write address where FSM should start
            Xil_Out32(XPAR_FSM_BRAM_RST_ADDR_BASEADDR,MAILBOX_DATA(9));
            fsm_status = READY_STATE;
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case CONFIG_TRACE:
            traceptr = (u8 *)MAILBOX_DATA(0);   // DDR address of the trace
            if(traceptr) {
                traceptr = (u8 *) ((u32) traceptr);
                tracing = 1;
            }
            trace_numofsamples = MAILBOX_DATA(1);
            msw_compare = MAILBOX_DATA(2);
            lsw_compare = MAILBOX_DATA(3);
            trace_status = READY_STATE;
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case RUN:
            // [11]:TRACE, [10]:FSM, [9]:PATTERN, [8]:BOOLEAN
            switch((cmd & 0xf00) >> 8) {
            case TRACE_FSM_PATTERN_BOOLEAN:
                run_tracebuffer();
                // issue start pulse to Trace,FSM,PATTERN with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x5D);
                // Keep BOOLEAN output enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x5C);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_FSM_PATTERN:
                run_tracebuffer();
                // issue start pulse to Trace, FSM, PATTERN with no BOOLEAN
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x1D);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x1C);
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_FSM_BOOLEAN:
                run_tracebuffer();
                // issue start pulse to Trace and FSM with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x59);
                // Keep BOOLEAN output enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x58);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                break;
            case TRACE_FSM:
                run_tracebuffer();
                // issue start pulse to Trace, FSM, with no BOOLEAN
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x19);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x18);
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                break;
            case TRACE_PATTERN_BOOLEAN:
                run_tracebuffer();
                // issue start pulse to Trace and PATTERN with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x55);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x54);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_PATTERN:
                run_tracebuffer();
                // issue start pulse to Trace, PATTERN, with no BOOLEAN
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x15);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x14);
                trace_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case FSM_PATTERN_BOOLEAN:
                // issue start pulse to FSM, PATTERN with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x4D);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x4C);
                boolean_status = RUN_STATE;
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case FSM_PATTERN:
                // issue start pulse to FSM, PATTERN with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x0D);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x0C);
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_BOOLEAN:
                run_tracebuffer();
                // issue start pulse to Trace with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x51);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x50);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                break;
            case TRACE:
                run_tracebuffer();
                // issue start pulse to Trace with BOOLEAN output disconnected
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x11);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x10);
                trace_status = RUN_STATE;
                break;
            case FSM_BOOLEAN:
                // issue start pulse to FSM with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x49);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x48);
                boolean_status = RUN_STATE;
                fsm_status = RUN_STATE;
                break;
            case FSM:
                // issue start pulse to FSM with BOOLEAN output disconnected
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x09); // 0x81);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x08); // 0x80);
                fsm_status = RUN_STATE;
                break;
            case BOOLEAN:
                // BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                break;
            case PATTERN_BOOLEAN:
                // issue start pulse to PATTERN with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x45);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x44);
                boolean_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case PATTERN:
                // issue start pulse to PATTERN with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x5);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x4);
                pattern_status = RUN_STATE;
                break;
            default:
                break;
            }
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case STEP:
            if(first_step == 0) {
                // save number of samples so can be restored when stopped
                saved_trace_numofsamples=trace_numofsamples;
                first_step = 1;
            }
            trace_numofsamples = 1;
            // [11]:TRACE, [10]:FSM, [9]:PATTERN, [8]:BOOLEAN
            switch((cmd & 0xf00) >> 8) {
            case TRACE_FSM_PATTERN_BOOLEAN:
                run_tracebuffer();
                // Issue step to Trace, FSM, PATTERN with BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x7C);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_FSM_PATTERN:
                run_tracebuffer();
                // Issue step to Trace, FSM, PATTERN with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x3C);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00);
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_FSM_BOOLEAN:
                run_tracebuffer();
                // Issue step to Trace and FSM with BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x78);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                break;
            case TRACE_FSM:
                run_tracebuffer();
                // Issue step to Trace and FSM with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x38);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00);
                trace_status = RUN_STATE;
                fsm_status = RUN_STATE;
                break;
            case TRACE_PATTERN_BOOLEAN:
                run_tracebuffer();
                // Issue step to Trace and PATTERN with BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x74);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_PATTERN:
                run_tracebuffer();
                // Issue step to Trace, PATTERN with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x34);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00);
                trace_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case FSM_PATTERN_BOOLEAN:
                // Issue step to Trace, FSM, PATTERN with BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x6C);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case FSM_PATTERN:
                // Issue step to FSM, PATTERN with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x2C);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00);
                fsm_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case TRACE_BOOLEAN:
                run_tracebuffer();
                // Issue step to Trace with BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x70);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                trace_status = RUN_STATE;
                break;
            case TRACE:
                run_tracebuffer();
                // Issue step to Trace with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x30);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00);
                trace_status = RUN_STATE;
                break;
            case FSM_BOOLEAN:
                // Issue step to FSM with BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x68);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                fsm_status = RUN_STATE;
                break;
            case FSM:
                // Issue step to FSM with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x28);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00);
                fsm_status = RUN_STATE;
                break;
            case BOOLEAN:
                // BOOLEAN enabled
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x60);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                break;
            case PATTERN_BOOLEAN:
                // Issue step to PATTERN with BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x64);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                boolean_status = RUN_STATE;
                pattern_status = RUN_STATE;
                break;
            case PATTERN:
                // Issue step to PATTERN with no BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x24);
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x0);
                pattern_status = RUN_STATE;
                break;
            default:
                break;
                }
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case STOP:
            // [11]:TRACE, [10]:FSM, [9]:PATTERN, [8]:BOOLEAN
            // engine(s) to be stop are in [11:8] of command
            if(cmd & 0x800) {
                control_read = Xil_In32(XPAR_CONTROLLERS_REG_BASEADDR);
                if(control_read & 0x40) {
                    // issue stop pulse to Trace with BOOLEAN output
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x52);
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x50);
                }
                else {
                    // issue stop pulse to Trace with no BOOLEAN output
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x12);
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00); // 10);
                }
                if(first_step) {
                    // restore saved number of samples during STEP
                    trace_numofsamples = saved_trace_numofsamples;
                    first_step = 0;
                }
                trace_status = READY_STATE;
            }
            if(cmd & 0x400) {
                control_read = Xil_In32(XPAR_CONTROLLERS_REG_BASEADDR);
                if(control_read & 0x40) {
                    // issue stop pulse to FSM with BOOLEAN output
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x4A);
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                }
                else {
                    // issue stop pulse to FSM with no BOOLEAN output
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x0A);
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00); // 08);
                }
                fsm_status = READY_STATE;
            }
            if(cmd & 0x200) {
                control_read = Xil_In32(XPAR_CONTROLLERS_REG_BASEADDR);
                if(control_read & 0x40) {
                    // issue stop pulse to PATTERN with BOOLEAN output
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x46);
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x40);
                }
                else {
                    // issue stop pulse to PATTERN with no BOOLEAN output
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x06);
                    Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x00); // 04);
                }
                pattern_status = READY_STATE;
            }
            if(cmd & 0x100) {
                // Disconnect BOOLEAN output
                Xil_Out32(XPAR_CONTROLLERS_REG_BASEADDR,0x0);
                boolean_status = READY_STATE;
            }
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case CHECK_STATUS:
            if(trace_status == RUN_STATE) {
                if(!(XAxiDma_Busy(&AxiDma,XAXIDMA_DEVICE_TO_DMA))) {
                    trace_status = READY_STATE;
                }
            }
            MAILBOX_DATA(0)= boolean_status;
            MAILBOX_DATA(1)= pattern_status;
            MAILBOX_DATA(2)= fsm_status;
            MAILBOX_DATA(3)= trace_status;
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case READ_INTF_SWITCH_CONFIG:
            MAILBOX_DATA(0)=Xil_In32(XPAR_FUNCTION_SEL_BASEADDR);
            MAILBOX_DATA(1)=Xil_In32(XPAR_FUNCTION_SEL_BASEADDR+8);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case RESET:
            // [11]:TRACE, [10]:FSM, [9]:PATTERN, [8]:BOOLEAN
            if(cmd & 0x800) {
                trace_status = RESET_STATE;
            }
            if(cmd & 0x400) {
                fsm_status = RESET_STATE;
            }
            if(cmd & 0x200) {
                pattern_status = RESET_STATE;
            }
            if(cmd & 0x100) {
                boolean_status = RESET_STATE;
            }
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_LCP_INTR_BASEADDR,0x0);
            MAILBOX_CMD_ADDR = 0x0;
            break;
        default:
            MAILBOX_CMD_ADDR = 0x0;
            break;
        }
    }
    return 0;
}


