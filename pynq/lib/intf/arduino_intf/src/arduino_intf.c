/*
 * arduino_intf_class.c
 *
 *  Created on: May 11, 2017
 *      Author: parimalp
 */

#include "xparameters.h"
#include <stdio.h>
#include "xaxicdma.h"	// AXI CDMA is used to move Pattern data from DDR to Block RAM
#include "xaxidma.h"	// AXI DMA is used to move tracebuffer data into DDR
#include "xil_exception.h"	// if interrupt is used
#include "xintc.h"		// if AXI_INTC is used
#include "xil_cache.h"
#include "xil_io.h"

#define INTC_DEVICE_ID		XPAR_INTC_0_DEVICE_ID
#define XPAR_TRACE_CNTRL_BASEADDR XPAR_XTRACE_CNTRL_0_S_AXI_TRACE_CNTRL_BASEADDR
#define XPAR_CFG_0_BASEADDR XPAR_IOP3_CFG_0_S_AXI_BASEADDR
#define XPAR_SMG_IO_SWITCH_BASEADDR XPAR_IOP3_SMG_0_SMG_IO_SWITCH_0_S00_AXI_BASEADDR

#define TRACE_CNTRL_ADDR_AP_CTRL 0x00	// [3:0] ap_ready, ap_idle, ap_done, ap_start
#define TRACE_CNTRL_DATA_COMPARE_LSW 0x10	// bits [31:0]
#define TRACE_CNTRL_DATA_COMPARE_MSW 0x14	// bits [63:32]
#define TRACE_CNTRL_LENGTH  0x1c	// 32-bit
#define TRACE_CNTRL_SAMPLE_RATE  0x24 // 32-bit

#define BUFFER_BASE 0x02000000
#define LENGTH XPAR_IOP3_AXI_BRAM_CTRL_0_S_AXI_HIGHADDR-XPAR_IOP3_AXI_BRAM_CTRL_0_S_AXI_BASEADDR+1  // 0x10000 source and destination buffers lengths in number of bytes

#define XPAR_SMG_BRAM_RST_ADDR_BASEADDR XPAR_IOP3_SMG_0_SMG_BRAM_RST_ADDR_BASEADDR
#define XPAR_GPIO_PG_TRI_CONTROL_BASEADDR XPAR_IOP3_PG_O_PG_AXI_GPIO_PG_TRI_CONTROL_BASEADDR
#define PG_CDMA_BRAM_MEMORY 0x10000000 	// CDMA access to PG BRAM
#define SMG_CDMA_BRAM_MEMORY 0xC0000000 // BRAM Port B mapped through 2nd BRAM Controller accessed by CDMA
#define SMG_CDMA_BRAM_MEMORY_SIZE 0x8000 // size in bytes
#define DDR_MEMORY 0x21000000

// commands and data from A9 to microblaze
#define MAILBOX_CMD_ADDR       (*(volatile u32 *)(0x0000FFFC))
#define MAILBOX_DATA(x)        (*(volatile u32 *)(0x0000F000 +((x)*4)))

// Commands
// Configure top-level interface_switch IP with desirable CFG, PG, SMG
// functionality on each header pin
#define INTF_SWITCH_CONFIG      0x1
#define READ_INTF_SWITCH_CONFIG 0xA
// CFG related command
#define CONFIG_CFG				0x2
#define READ_CFG_DIRECTION		0xC
// PG related command
#define CONFIG_PG				0x3
// SMG related command
// Use TRACE_ONLY command to capture the trace after SMG is running
#define CONFIG_SMG				0x4
// The following command allows to trace data
#define CONFIG_TRACE			0x5
// The following commands allow arming each unit
#define ARM_CFG					0x6
#define ARM_PG					0x7
#define ARM_SMG					0x8
#define ARM_TRACE				0x9
// The following command will run and stop
#define RUN						0xD
#define STOP					0xE
// The following command will query run status, 1 means running, 0 otherwise
// CFG [3], TRACE [2], SMG [1], PG [0]
#define RUN_STATUS				0xF

// Defines running functional units
#define CFG_TRACE_SMG_PG		0xF
#define TRACE_SMG_PG			0x7
#define CFG_TRACE_SMG			0xE
#define TRACE_SMG				0x6
#define CFG_TRACE_PG			0xD
#define TRACE_PG				0x5
#define CFG_SMG_PG				0xB
#define SMG_PG					0x3
#define CFG						0x8
#define CFG_TRACE				0xC
#define TRACE					0x4
#define CFG_SMG					0xA
#define SMG						0x2
#define CFG_PG					0x9
#define PG						0x1

u32 tracing=0;
int CDMA_Status, Status, i;
int pg_numofsamples, smg_numofsamples, trace_numofsamples, stop_issued;
u8 * pg_source, * smg_source, * destination, * traceptr;
u32 pg_direction, smg_direction;
u32 reg0, reg1, reg2, reg3, reg4, reg5, reg6;

// CFG related
u32 cmd, cmd1;

// AXI CDMA related definitions
XAxiCdma xcdma;
XAxiCdma_Config * CdmaCfgPtr;

// AXI DMA related definitions
XAxiDma AxiDma;
XAxiDma_Config *CfgPtr;

u32 pg_tracing, pg_multiple, pg_configured, smg_configured, trace_configured;
u32 msw_compare, lsw_compare;
u32 arm_cfg, arm_pg, arm_smg, arm_trace, arm_vector;
u32 cfg_running, trace_running, pg_running, smg_running;

int pg(void) {
	pg_tracing = 0;
	pg_multiple = 0;
	pg_configured = 0;
	pg_direction = MAILBOX_DATA(0);						// I/O direction
	pg_source = (u8 *)MAILBOX_DATA(1);					// DDR address where pattern is passed
	pg_source = (u8 *) ((u32) pg_source | 0x20000000);
	pg_numofsamples = MAILBOX_DATA(2);						// number of words in the pattern
	// move pattern data from DDR memory to BlockRAM
	destination = (u8 *)PG_CDMA_BRAM_MEMORY;
	XAxiCdma_IntrDisable(&xcdma, XAXICDMA_XR_IRQ_ALL_MASK);
	Xil_DCacheFlushRange((UINTPTR)&pg_source, pg_numofsamples*4);
	Status = XAxiCdma_SimpleTransfer(&xcdma, (u32) pg_source, (u32) destination, pg_numofsamples*4, NULL, NULL);
	if (Status != XST_SUCCESS) {
		CDMA_Status = XAxiCdma_GetError(&xcdma);
		if (CDMA_Status != 0x0) {
			XAxiCdma_Reset(&xcdma);
			return 0xFFFF0003;								// return error code
		}
	}
	while (XAxiCdma_IsBusy(&xcdma)); // Wait for DMA to complete
	CDMA_Status = XAxiCdma_GetError(&xcdma);
	if (CDMA_Status != 0x0) {
		XAxiCdma_Reset(&xcdma);
		return 0xFFFF0004;									// return error code
	}
	if(MAILBOX_DATA(3))
		pg_multiple=1;
	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR,pg_direction); 	// I/O direction to GPIO Channel 1 data
	Xil_Out32(XPAR_IOP3_PG_O_PG_AXI_GPIO_PG_NSAMPLES_SINGLE_BASEADDR,pg_numofsamples); // number of samples
	Xil_Out32(XPAR_IOP3_PG_O_PG_AXI_GPIO_PG_NSAMPLES_SINGLE_BASEADDR+8,pg_multiple); // single/multiple
	pg_configured=1;
	return 0;
}

int run_tracebuffer(void) {
	// setup and enable tracebuffer engine components
	XAxiDma_Reset(&AxiDma);
	// Wait for reset to complete
	while(!XAxiDma_ResetIsDone(&AxiDma));
	// Configure Stream DMA controller
	Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) traceptr, trace_numofsamples*8,
			XAXIDMA_DEVICE_TO_DMA);
	if (Status != XST_SUCCESS) {
		Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
		Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
		MAILBOX_DATA(0) = 0xFFFF0008;						// return error code
		return 1;
	}
	// Setup the trace controller
	Xil_Out32(XPAR_TRACE_CNTRL_BASEADDR+TRACE_CNTRL_LENGTH,trace_numofsamples); // number of samples
	Xil_Out32(XPAR_TRACE_CNTRL_BASEADDR+TRACE_CNTRL_DATA_COMPARE_MSW,msw_compare); // MS word of trigger mask
	Xil_Out32(XPAR_TRACE_CNTRL_BASEADDR+TRACE_CNTRL_DATA_COMPARE_LSW,lsw_compare); // LS word of trigger mask
	Xil_Out32(XPAR_TRACE_CNTRL_BASEADDR+TRACE_CNTRL_ADDR_AP_CTRL,0x1); // Issue start, Start=1
	Xil_Out32(XPAR_TRACE_CNTRL_BASEADDR+TRACE_CNTRL_ADDR_AP_CTRL,0x0); // Start=0
	return 0;
}

int main (void) {

    int status;

    // Set direction register of INTR and set it low
	Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR+4,0x0); // output
    Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);   // make sure it is low

	// Setup DMA Controller
    CdmaCfgPtr = XAxiCdma_LookupConfig(XPAR_IOP3_AXI_CDMA_0_DEVICE_ID);
   	if (!CdmaCfgPtr) {
   		return XST_FAILURE;
   	}

   	Status = XAxiCdma_CfgInitialize(&xcdma , CdmaCfgPtr, CdmaCfgPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
		xil_printf("Status=%x\r\n",Status);
	}

	/* Initialize the XAxiDma device.	 */
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

	// tristate cfg output as default
	Xil_Out32(XPAR_CFG_0_BASEADDR+4*48,0xffffffff);

	// set all Arduino header pins as unused as default
	Xil_Out32(XPAR_IOP3_FUNCTION_SEL_BASEADDR,0xffffffff);		// function select for pins 9:0
	Xil_Out32(XPAR_IOP3_FUNCTION_SEL_BASEADDR+8,0xffffffff); 	// function select for pins 19:10

	while(1) {
		while(MAILBOX_CMD_ADDR==0); // wait for CMD to be issued
		cmd = MAILBOX_CMD_ADDR;

		switch(cmd & 0x0f) {
		case INTF_SWITCH_CONFIG:
			Xil_Out32(XPAR_IOP3_FUNCTION_SEL_BASEADDR,MAILBOX_DATA(0));	  // function select for pins 9:0
			Xil_Out32(XPAR_IOP3_FUNCTION_SEL_BASEADDR+8,MAILBOX_DATA(1)); // function select for pins 19:10
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
	    case CONFIG_CFG:
	    	for(i=0; i<48; i++)
	    		Xil_Out32(XPAR_CFG_0_BASEADDR+4*i,MAILBOX_DATA(i));
	    	Xil_Out32(XPAR_CFG_0_BASEADDR+4*48,MAILBOX_DATA(48));
	    	Xil_Out32(XPAR_CFG_0_BASEADDR+4*49,MAILBOX_DATA(49) | 0x80000000);
	    	Xil_Out32(XPAR_CFG_0_BASEADDR+4*49,MAILBOX_DATA(49));
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
	    case READ_CFG_DIRECTION:
	    	MAILBOX_DATA(0)=Xil_In32(XPAR_CFG_0_BASEADDR+4*48);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case CONFIG_PG:
			status=pg();
			MAILBOX_DATA(0)=status;
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case CONFIG_SMG:
			smg_configured = 0;
			reg0 = MAILBOX_DATA(0);								// input select for pins 0,1,2,3
			reg1 = MAILBOX_DATA(1);								// input select for pins 4,5,6,7
			reg2 = MAILBOX_DATA(2);								// output select for pins 0,1,2,3
			reg3 = MAILBOX_DATA(3);								// output select for pins 4,5,6,7
			reg4 = MAILBOX_DATA(4);								// output select for pins 8,9,10,11
			reg5 = MAILBOX_DATA(5);								// output select for pins 12,13,14,15
			reg6 = MAILBOX_DATA(6);								// output select for pins 16,17,18,19
			smg_direction = MAILBOX_DATA(7);						// I/O direction
			smg_source = (u8 *)MAILBOX_DATA(8);					// DDR address where pattern is passed
			smg_source = (u8 *) ((u32) smg_source | 0x20000000);
			// move pattern data from DDR memory to BlockRAM
			destination = (u8 *)SMG_CDMA_BRAM_MEMORY;
			XAxiCdma_IntrDisable(&xcdma, XAXICDMA_XR_IRQ_ALL_MASK);
			Xil_DCacheFlushRange((UINTPTR)&smg_source, SMG_CDMA_BRAM_MEMORY_SIZE);
			Status = XAxiCdma_SimpleTransfer(&xcdma, (u32) smg_source, (u32) destination, SMG_CDMA_BRAM_MEMORY_SIZE, NULL, NULL);
			if (Status != XST_SUCCESS) {
				CDMA_Status = XAxiCdma_GetError(&xcdma);
				if (CDMA_Status != 0x0) {
					XAxiCdma_Reset(&xcdma);
		            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
		            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
					MAILBOX_DATA(0) = 0xFFFF0006;				// return error code
					break;
				}
			}
			while (XAxiCdma_IsBusy(&xcdma)); 					// Wait for DMA to complete
			CDMA_Status = XAxiCdma_GetError(&xcdma);
			if (CDMA_Status != 0x0) {
				XAxiCdma_Reset(&xcdma);
	            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
	            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
				MAILBOX_DATA(0) = 0xFFFF0007;					// return error code
				break;
			}
			// Setup the SMG
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR,reg0);		// configure to either use NS [8:5] or external pin
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR+4,reg1);		// configure to use external pins
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR+8,reg2);		// configure output bits [3:0]
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR+0xc,reg3);	// configure output bits [7:4]
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR+0x10,reg4);	// configure output bits [11:8]
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR+0x14,reg5);	// configure output bits [15:12]
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR+0x18,reg6);	// configure output bits [19:16]
			Xil_Out32(XPAR_SMG_IO_SWITCH_BASEADDR+0x1c,smg_direction);	// configure direction for all 20 header pins
			Xil_Out32(XPAR_SMG_BRAM_RST_ADDR_BASEADDR,MAILBOX_DATA(9));	// Write address where SMG should start
			smg_configured=1;
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case CONFIG_TRACE:
			trace_configured = 0;
			traceptr = (u8 *)MAILBOX_DATA(0);						// DDR address where trace will be saved
			if(traceptr) {
				traceptr = (u8 *) ((u32) traceptr | 0x20000000);
				tracing = 1;
			}
			trace_numofsamples = MAILBOX_DATA(1);
			msw_compare = MAILBOX_DATA(2);
			lsw_compare = MAILBOX_DATA(3);
			trace_configured = 1;
			Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
			Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case ARM_CFG:
           	arm_cfg=1;
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case ARM_PG:
            if(pg_configured)
            	arm_pg=1;
            else
            	arm_pg=0;
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case ARM_SMG:
            if(smg_configured)
            	arm_smg=1;
            else
            	arm_smg=0;
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case ARM_TRACE:
            if(trace_configured) {
            	arm_trace=1;
            }
            else
            	arm_trace=0;
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case RUN:
			if(!(XAxiDma_Busy(&AxiDma,XAXIDMA_DEVICE_TO_DMA))) trace_running=0;
			arm_vector = ((arm_cfg & !cfg_running)<< 3) | ((arm_trace & !trace_running) << 2) | ((arm_smg & !smg_running) << 1) | (arm_pg & !pg_running);
            switch(arm_vector) {
            case CFG_TRACE_SMG_PG:
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x79);	// issue start pulse to Trace, SMG, PG with CFG enabled
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x78);	// Keep CFG output enabled
				cfg_running=1;
				trace_running=1;
				smg_running=1;
				pg_running=1;
            	break;
            case TRACE_SMG_PG:	// controlled by PG's number of samples?
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x39);	// issue start pulse to Trace, SMG, PG with CFG output disconnected
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x38);	// issue start pulse
				trace_running=1;
				smg_running=1;
				pg_running=1;
            	break;
            case CFG_TRACE_SMG:
				// Issue start to Trace and SMG engines
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x71);	// issue start pulse to Trace and SMG with CFG enabled
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x70);	// Keep CFG output enabled
				cfg_running=1;
				trace_running=1;
				smg_running=1;
            	break;
            case TRACE_SMG:	// controlled by TRACE's number of samples
				// Issue start to Trace and SMG engines
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x31);	// issue start pulse to Trace and SMG with CFG output disconnected
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x30);	// issue start pulse
				trace_running=1;
				smg_running=1;
            	break;
            case CFG_TRACE_PG:
				// Issue start to Trace and PG engines
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x69);	// issue start pulse to Trace and PG with CFG enabled
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x68);	// Keep CFG output enabled
				cfg_running=1;
				trace_running=1;
				pg_running=1;
            	break;
            case TRACE_PG:
				// Issue start to Trace and PG engines
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x29);	// issue start pulse to Trace and PG with CFG output disconnected
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x28);	//
				trace_running=1;
				pg_running=1;
            	break;
            case CFG_SMG_PG:
				// Issue start to SMG and PG engines
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x59);	// issue start pulse to Trace, SMG, PG with CFG enabled
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x58);	// Keep CFG output enabled
				cfg_running=1;
				smg_running=1;
				pg_running=1;
            	break;
            case SMG_PG:
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x19);	// issue start pulse to Trace, SMG, PG with CFG output disconnected
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x18);	// issue start pulse
				smg_running=1;
				pg_running=1;
            	break;
            case CFG_TRACE:
				// Issue start to Trace
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x61);	// issue start pulse to Trace with CFG enabled
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x60);	// Keep CFG output enabled
				cfg_running=1;
				trace_running=1;
            	break;
            case TRACE:
				// Issue start to Trace
            	run_tracebuffer();
            	Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x21);	// issue start pulse to Trace with CFG output disconnected
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x20);	// issue start pulse
				trace_running=1;
            	break;
            case CFG_SMG:
				// Issue start to SMG
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x51);	// issue start pulse to SMG with CFG enabled
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x50);	// Keep CFG output enabled
				cfg_running=1;
				smg_running=1;
            	break;
            case SMG:
				// Issue start to SMG
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x11);	// issue start pulse to SMG with CFG output disconnected
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x10);
				smg_running=1;
            	break;
            case CFG:
				// Enable CFG output
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x40);	// CFG enabled
				cfg_running=1;
            	break;
            case CFG_PG:
				// Issue start to PG
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x49);	// issue start pulse to PG with CFG enabled
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x48);	// Keep CFG output enabled
				cfg_running=1;
				pg_running=1;
            	break;
            case PG:
				// Issue start to PG
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x9);		// issue start pulse to PG with CFG output disconnected
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x8);
				pg_running=1;
            	break;
            default:
            	break;
            }
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case STOP:
			if(trace_running) {
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x24);	// issue stop pulse to Trace
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x20);	//
				trace_running=0;
				arm_trace=0;
			}
			if(smg_running) {
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x14);	// issue stop pulse to SMG
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x10);	//
				smg_running=0;
				arm_smg=0;
			}
			if(pg_running) {
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x0C);	// issue stop pulse to PG
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x08);	//
				pg_running=0;
				arm_pg=0;
			}
			if(cfg_running) {
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x0);	// Disconnect CFG output
				cfg_running=0;
				arm_cfg=0;
			}
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case RUN_STATUS:
			if(!(XAxiDma_Busy(&AxiDma,XAXIDMA_DEVICE_TO_DMA))) {
				trace_running=0;
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x24);	// issue stop pulse to Trace
				Xil_Out32(XPAR_GPIO_PG_TRI_CONTROL_BASEADDR+8,0x20);	//
			}
			MAILBOX_DATA(0)= (cfg_running << 3) | (trace_running << 2) | (smg_running << 1) | pg_running;
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case READ_INTF_SWITCH_CONFIG:
			MAILBOX_DATA(0)=Xil_In32(XPAR_IOP3_FUNCTION_SEL_BASEADDR);	  // function select for pins 9:0
			MAILBOX_DATA(1)=Xil_In32(XPAR_IOP3_FUNCTION_SEL_BASEADDR+8); // function select for pins 19:10
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x1);
            Xil_Out32(XPAR_IOP3_IOP3_INTR_BASEADDR,0x0);
			MAILBOX_CMD_ADDR = 0x0;
			break;
		default:
			MAILBOX_CMD_ADDR = 0x0;
			break;
		}
	}
	return 0;
}


