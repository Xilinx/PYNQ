/******************************************************************************
*
* Copyright (C) 2002 - 2015 Xilinx, Inc.  All rights reserved.
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
/*****************************************************************************/
/**
*
* @file xiic.h
* @addtogroup iic_v3_1
* @{
* @details
*
* XIic is the driver for an IIC master or slave device.
*
* In order to reduce the memory requirements of the driver the driver is
* partitioned such that there are optional parts of the driver.
* Slave, master, and multimaster features are optional such that all these files
* are not required at the same time.
* In order to use the slave and multimaster features of the driver, the user
* must call functions (XIic_SlaveInclude and XIic_MultiMasterInclude)
* to dynamically include the code. These functions may be called at any time.
*
* Two sets of higher level API's are available in the XIic driver that can
* be used for Transmission/Reception in Master mode :
* - XIic_MasterSend()/ XIic_MasterRecv() which is used in normal mode.
* - XIic_DynMasterSend()/ XIic_DynMasterRecv() which is used in Dynamic mode.
*
* Similarly two sets of lower level API's are available in XIic driver that
* can be used for Transmission/Reception in Master mode:
* - XIic_Send()/ XIic_Recv() which is used in normal mode
* - XIic_DynSend()/ XIic_DynRecv() which is used in Dynamic mode.
*
* The user should use a single set of APIs as per his requirement and
* should not intermix them.
*
* All the driver APIs can be used for read, write and  combined mode of
* operations on the IIC bus.
*
* In the normal mode IIC support both 7-bit and 10-bit addressing, and in
* the dynamic mode support only 7-bit addressing.
*
* <b>Initialization & Configuration</b>
*
* The XIic_Config structure is used by the driver to configure itself. This
* configuration structure is typically created by the tool-chain based on HW
* build properties.
*
* To support multiple runtime loading and initialization strategies employed
* by various operating systems, the driver instance can be initialized in one
* of the following ways:
*
*   - XIic_Initialize() - The driver looks up its own
*     configuration structure created by the tool-chain based on an ID provided
*     by the tool-chain.
*
*   - XIic_CfgInitialize() - The driver uses a configuration structure provided
*     by the caller. If running in a system with address translation, the
*     provided virtual memory base address replaces the physical address present
*     in the configuration structure.
*
* <b>General Purpose Output</b>
* The IIC hardware provides a General Purpose Output Register that allows the
* user to connect general purpose outputs to devices, such as a write protect,
* for an EEPROM. This register is parameterizable in the hardware such that
* there could be zero bits in this register and in this case it will cause
* a bus error if read or written.
*
* <b>Bus Throttling</b>
*
* The IIC hardware provides bus throttling which allows either the device, as
* either a master or a slave, to stop the clock on the IIC bus. This feature
* allows the software to perform the appropriate processing for each interrupt
* without an unreasonable response restriction.  With this design, it is
* important for the user to understand the implications of bus throttling.
*
* <b>Repeated Start</b>
*
* An application can send multiple messages, as a master, to a slave device
* and re-acquire the IIC bus each time a message is sent. The repeated start
* option allows the application to send multiple messages without re-acquiring
* the IIC bus for each message. The transactions involving repeated start
* are also called combined transfers if there is Read and Write in the
* same transaction.
*
* The repeated start feature works with all the API's in XIic driver.
*
* The Repeated Start feature also could cause the application to lock up, or
* monopolize the IIC bus, should repeated start option be enabled and sequences
* of messages never end(periodic data collection).
* Also when repeated start is not disable before the last master message is
* sent or received, will leave the bus captive to the master, but unused.
*
* <b>Addressing</b>
*
* The IIC hardware is parameterized such that it can be built for 7 or 10
* bit addresses. The driver provides the ability to control which address
* size is sent in messages as a master to a slave device.  The address size
* which the hardware responds to as a slave is parameterized as 7 or 10 bits
* but fixed by the hardware build.
*
* Addresses are represented as hex values with no adjustment for the data
* direction bit as the software manages address bit placement. This is
* especially important as the bit placement is not handled the same depending
* on which options are used such as repeated start and 7 vs 10 bit addessing.
*
* <b>Data Rates</b>
*
* The IIC hardware is parameterized such that it can be built to support
* data rates from DC to 400KBit. The frequency of the interrupts which
* occur is proportional to the data rate.
*
* <b>Polled Mode Operation</b>
*
* This driver does not provide a polled mode of operation primarily because
* polled mode which is non-blocking is difficult with the amount of
* interaction with the hardware that is necessary.
*
* <b>Interrupts</b>
*
* The device has many interrupts which allow IIC data transactions as well
* as bus status processing to occur.
*
* The interrupts are divided into two types, data and status. Data interrupts
* indicate data has been received or transmitted while the status interrupts
* indicate the status of the IIC bus. Some of the interrupts, such as Not
* Addressed As Slave and Bus Not Busy, are only used when these specific
* events must be recognized as opposed to being enabled at all times.
*
* Many of the interrupts are not a single event in that they are continuously
* present such that they must be disabled after recognition or when undesired.
* Some of these interrupts, which are data related, may be acknowledged by the
* software by reading or writing data to the appropriate register, or must
* be disabled. The following interrupts can be continuous rather than single
* events.
*   - Data Transmit Register Empty/Transmit FIFO Empty
*   - Data Receive Register Full/Receive FIFO
*   - Transmit FIFO Half Empty
*   - Bus Not Busy
*   - Addressed As Slave
*   - Not Addressed As Slave
*
* The following interrupts are not passed directly to the application thru the
* status callback.  These are only used internally for the driver processing
* and may result in the receive and send handlers being called to indicate
* completion of an operation.  The following interrupts are data related
* rather than status.
*   - Data Transmit Register Empty/Transmit FIFO Empty
*   - Data Receive Register Full/Receive FIFO
*   - Transmit FIFO Half Empty
*   - Slave Transmit Complete
*
* <b>Interrupt To Event Mapping</b>
*
* The following table provides a mapping of the interrupts to the events which
* are passed to the status handler and the intended role (master or slave) for
* the event. Some interrupts can cause multiple events which are combined
* together into a single status event such as XII_MASTER_WRITE_EVENT and
* XII_GENERAL_CALL_EVENT
* <pre>
* Interrupt                         Event(s)                      Role
*
* Arbitration Lost Interrupt        XII_ARB_LOST_EVENT            Master
* Transmit Error                    XII_SLAVE_NO_ACK_EVENT        Master
* IIC Bus Not Busy                  XII_BUS_NOT_BUSY_EVENT        Master
* Addressed As Slave                XII_MASTER_READ_EVENT,        Slave
*                                   XII_MASTER_WRITE_EVENT,       Slave
*                                   XII_GENERAL_CALL_EVENT        Slave
* </pre>
* <b>Not Addressed As Slave Interrupt</b>
*
* The Not Addressed As Slave interrupt is not passed directly to the
* application thru the status callback.  It is used to determine the end of
* a message being received by a slave when there was no stop condition
* (repeated start).  It will cause the receive handler to be called to
* indicate completion of the operation.
*
* <b>RTOS Independence</b>
*
* This driver is intended to be RTOS and processor independent.  It works
* with physical addresses only.  Any needs for dynamic memory management,
* threads or thread mutual exclusion, virtual memory, or cache control must
* be satisfied by the layer above this driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.01a rfp  10/19/01 release
* 1.01c ecm  12/05/02 new rev
* 1.01d jhl  10/08/03 Added general purpose output feature
* 1.01d sv   05/09/05 Changed the data being written to the Address/Control
*                     Register and removed the code for testing the
*                     Receive Data Register in XIic_SelfTest function of
*                     xiic_selftest.c source file
* 1.02a jvb  12/14/05 I separated dependency on the static config table and
*                     xparameters.h from the driver initialization by moving
*                     _Initialize and _LookupConfig to _sinit.c. I also added
*                     the new _CfgInitialize routine.
* 1.02a mta  03/09/06 Added a new function XIic_IsIicBusy() which returns
*			whether IIC Bus is Busy or Free.
* 1.02a mta  03/09/06 Implemented Repeated Start in the Low Level Driver.
* 1.03a mta  07/17/06 Added files to support Dynamic IIC controller in High
*		      level driver. Added xiic_dyn_master.c. Added support
* 		      for IIC Dynamic controller in Low level driver in xiic_l.c
* 1.13a wgr  03/22/07 Converted to new coding style.
* 1.13b ecm  11/29/07 added BB polling loops to the DynSend and DynRecv
*		      routines to handle the race condition with BNB in IISR.
* 1.14a sdm  08/22/08 Removed support for static interrupt handlers from the MDD
*		      file
* 1.14a ecm  11/13/08 changed BB polling loops in DynRecv to handle race
*		      condition, CR491889. DynSend was correct from v1.13.b
* 1.15a ktn  02/17/09 Fixed XIic_GetAddress() to return correct device address.
* 1.16a ktn  07/17/09 Updated the XIic_SelfTest() to test only Interrupt
*		      Registers.
* 2.00a ktn  10/22/09 Converted all register accesses to 32 bit access.,
*		      Removed the macro XIIC_RESET, XIic_Reset API should be
*		      used in its place.
*		      Removed the XIIC_CLEAR_STATS macro, XIic_ClearStats API
*		      should be used in its place.
*		      Removed the macro XIic_mEnterCriticalRegion,
*		      XIic_IntrGlobalDisable should be used in its place.
*		      Removed the macro XIic_mExitCriticalRegion,
*		      XIic_IntrGlobalEnable should be used in its place.
*		      Some of the macros have been renamed to remove _m from
*		      the name see the xiic_i.h and xiic_l.h file for further
*		      information (Example XIic_mClearIntr is now
*		      XIic_ClearIntr).
*		      Some of the macros have been renamed to be consistent,
*		      see the xiic_l.h file for further information
*		      (Example XIIC_WRITE_IIER is renamed as XIic_WriteIier).
*		      The driver has been updated to use the HAL APIs/macros
*		      (Example XASSERT_NONVOID is now Xil_AssertNonvoid)
* 2.01a ktn  04/09/10 Updated TxErrorhandler in xiic_intr.c to be called for
*		      Master Transmitter case based on Addressed As Slave (AAS)
*		      bit rather than MSMS bit(CR 540199).
* 2.02a sdm  10/08/10 Updated to disable the device at the end of the transfer,
*		      using Addressed As Slave (AAS) bit when addressed as
*		      slave in XIic_Send for CR565373.
* 2.03a rkv  01/25/11 Updated in NAAS interrupt handler to support data
*		      recieved less than FIFO size prior to NAAS interrupt.
*		      Fixed for CR590212.
* 2.04a sdm  07/22/11 Added IsSlaveSetAckOff flag to the instance structure.
*		      This flag is set when the Slave has set the Ack Off in the
*		      RecvSlaveData function (xiic_slave.c) and
*		      is cleared in the NotAddrAsSlaveHandler (xiic_slave.c)
*		      when the master has released the bus. This flag is
*		      to be used by slave applications for recovering when it
*		      has gone out of sync with the master for CR 615004.
*		      Removed a compiler warning in XIic_Send (xiic_l.c)
* 2.05a bss  02/05/12 Assigned RecvBufferPtr in XIic_MasterSend API and
*		      SendBufferPtr in XIic_MasterRecv to NULL in xiic_master.c
* 2.06a bss  02/14/13 Modified TxErrorHandler in xiic_intr.c to fix CR #686483
*		      Modified xiic_eeprom_example.c to fix CR# 683509.
*		      Modified bitwise OR to logical OR in
*		      XIic_InterruptHandler API in xiic_intr.c.
* 2.07a adk  18/04/13 Updated the code to avoid unused variable warnings
*	              when compiling with the -Wextra -Wall flags.
*	              Changes done in files xiic.c and xiic_i.h. CR:705001
* 2.08a adk  29/07/13 In Low level driver In repeated start condition the
*		      Direction of Tx bit must be disabled in recv condition
*		      It Fixes the CR:685759 Changes are done in the file
*		      xiic_l.c in the function XIic_Recv.
* 3.0   adk  19/12/13 Updated as per the New Tcl API's
* 3.1   adk  01/08/15 When configured as a slave return the actual number of
*                     bytes have been received/sent by the Master
*                     to the user callback (CR: 828504). Changes are made in the
*		      file xiic_slave.c.
* </pre>
*
******************************************************************************/
#ifndef XIIC_H			/* prevent circular inclusions */
#define XIIC_H			/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xiic_l.h"

/************************** Constant Definitions *****************************/

/** @name Configuration options
 *
 * The following options may be specified or retrieved for the device and
 * enable/disable additional features of the IIC bus. Each of the options
 * are bit fields such that more than one may be specified.
 * @{
 */
/**
 * <pre>
 * XII_GENERAL_CALL_OPTION	The general call option allows an IIC slave to
 *				recognized the general call address. The status
 *				handler is called as usual indicating the device
 *				has been addressed as a slave with a general
 *				call. It is the application's responsibility to
 *				perform any special processing for the general
 *				call.
 *
 * XII_REPEATED_START_OPTION	The repeated start option allows multiple
 *				messages to be sent/received on the IIC bus
 *				without rearbitrating for the bus.  The messages
 *				are sent as a series of messages such that the
 *				option must be enabled before the 1st message of
 *				the series, to prevent an stop condition from
 *				being generated on the bus, and disabled before
 *				the last message of the series, to allow the
 *				stop condition to be generated.
 *
 * XII_SEND_10_BIT_OPTION	The send 10 bit option allows 10 bit addresses
 *				to be sent on the bus when the device is a
 *				master. The device can be configured to respond
 *				as to 7 bit addresses even though it may be
 *				communicating with other devices that support 10
 *				bit addresses.  When this option is not enabled,
 *				only 7 bit addresses are sent on the bus.
 *
 * </pre>
 */
#define XII_GENERAL_CALL_OPTION		0x00000001
#define XII_REPEATED_START_OPTION	0x00000002
#define XII_SEND_10_BIT_OPTION		0x00000004

/*@}*/

/** @name Status events
 *
 * The following status events occur during IIC bus processing and are passed
 * to the status callback. Each event is only valid during the appropriate
 * processing of the IIC bus. Each of these events are bit fields such that
 * more than one may be specified.
 * @{
 */
#define XII_BUS_NOT_BUSY_EVENT	0x00000001 /**< Bus transitioned to not busy */
#define XII_ARB_LOST_EVENT	0x00000002 /**< Arbitration was lost */
#define XII_SLAVE_NO_ACK_EVENT	0x00000004 /**< Slave did not ACK (had error) */
#define XII_MASTER_READ_EVENT	0x00000008 /**< Master reading from slave */
#define XII_MASTER_WRITE_EVENT	0x00000010 /**< Master writing to slave */
#define XII_GENERAL_CALL_EVENT	0x00000020 /**< General call to all slaves */
/*@}*/


/*
 * The following address types are used when setting and getting the addresses
 * of the driver. These are mutually exclusive such that only one or the other
 * may be specified.
 */
#define XII_ADDR_TO_SEND_TYPE	 1 /**< Bus address of slave device */
#define XII_ADDR_TO_RESPOND_TYPE 2 /**< This device's bus address as slave */

/**************************** Type Definitions *******************************/

/**
 * This typedef contains configuration information for the device.
 */
typedef struct {
	u16 DeviceId;	  /**< Unique ID  of device */
	u32 BaseAddress;  /**< Device base address */
	int Has10BitAddr; /**< Does device have 10 bit address decoding */
	u8 GpOutWidth;	  /**< Number of bits in general purpose output */
} XIic_Config;

/****************************************************************************/
/**
* This callback function data type is defined to handle the asynchronous
* processing of sent and received data of the IIC driver.  The application
* using this driver is expected to define a handler of this type to support
* interrupt driven mode. The handlers are called in an interrupt context such
* that minimal processing should be performed. The handler data type is
* utilized for both send and receive handlers.
*
* @param	CallBackRef is a callback reference passed in by the upper
*		layer when setting the callback functions, and passed back
*		to the upper layer when the callback is invoked. Its type is
*		unimportant to the driver  component, so it is a void pointer.
* @param	ByteCount indicates the number of bytes remaining to be sent or
*		received.  A value of zero indicates that the requested number
*		of bytes were sent or received.
*
******************************************************************************/
typedef void (*XIic_Handler) (void *CallBackRef, int ByteCount);

/******************************************************************************/
/**
* This callback function data type is defined to handle the asynchronous
* processing of status events of the IIC driver.  The application using
* this driver is expected to define a handler of this type to support
* interrupt driven mode. The handler is called in an interrupt context such
* that minimal processing should be performed.
*
* @param	CallBackRef is a callback reference passed in by the upper
*		layer when setting the callback functions, and passed back
*		to the upper layer when the callback is invoked. Its type is
*		unimportant to the driver component, so it is a void pointer.
* @param	StatusEvent indicates one or more status events that occurred.
*		See the definition of the status events above.
*
********************************************************************************/
typedef void (*XIic_StatusHandler) (void *CallBackRef, int StatusEvent);

/**
 * XIic statistics
 */
typedef struct {
	u8 ArbitrationLost;/**< Number of times arbitration was lost */
	u8 RepeatedStarts; /**< Number of repeated starts */
	u8 BusBusy;	   /**< Number of times bus busy status returned */
	u8 RecvBytes;	   /**< Number of bytes received */
	u8 RecvInterrupts; /**< Number of receive interrupts */
	u8 SendBytes;	   /**< Number of transmit bytes received */
	u8 SendInterrupts; /**< Number of transmit interrupts */
	u8 TxErrors;	   /**< Number of transmit errors (no ack) */
	u8 IicInterrupts;  /**< Number of IIC (device) interrupts */
} XIicStats;

/**
 * The XIic driver instance data. The user is required to allocate a
 * variable of this type for every IIC device in the system. A pointer
 * to a variable of this type is then passed to the driver API functions.
 */
typedef struct {
	XIicStats Stats;	/**< Statistics */
	u32 BaseAddress;	/**< Device base address */
	int Has10BitAddr;	/**< TRUE when 10 bit addressing in design */
	int IsReady;		/**< Device is initialized and ready */
	int IsStarted;		/**< Device has been started */
	int AddrOfSlave;	/**< Slave Address writing to */

	u32 Options;		/**< Current operating options */
	u8 *SendBufferPtr;	/**< Buffer to send (state) */
	u8 *RecvBufferPtr;	/**< Buffer to receive (state) */
	u8 TxAddrMode;		/**< State of Tx Address transmission */
	int SendByteCount;	/**< Number of data bytes in buffer (state)  */
	int RecvByteCount;	/**< Number of empty bytes in buffer (state) */

	u32 BNBOnly;		/**< TRUE when BNB interrupt needs to */
				/**< call callback  */
	u8 GpOutWidth;		/**< General purpose output width */

	XIic_StatusHandler StatusHandler; /**< Status Handler */
	void *StatusCallBackRef;  /**< Callback reference for status handler */
	XIic_Handler RecvHandler; /**< Receive Handler */
	void *RecvCallBackRef;	  /**< Callback reference for Recv handler */
	XIic_Handler SendHandler; /**< Send Handler */
	void *SendCallBackRef;	  /**< Callback reference for send handler */
	int IsDynamic;		  /**< TRUE when Dynamic control is used */
	int IsSlaveSetAckOff;	  /**< TRUE when Slave has set the ACK Off */

} XIic;

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/*
 * Initialization functions in xiic_sinit.c
 */
int XIic_Initialize(XIic *InstancePtr, u16 DeviceId);
XIic_Config *XIic_LookupConfig(u16 DeviceId);

/*
 * Functions in xiic.c
 */
int XIic_CfgInitialize(XIic *InstancePtr, XIic_Config *Config,
		       u32 EffectiveAddr);

int XIic_Start(XIic *InstancePtr);
int XIic_Stop(XIic *InstancePtr);

void XIic_Reset(XIic *InstancePtr);

int XIic_SetAddress(XIic *InstancePtr, int AddressType, int Address);
u16 XIic_GetAddress(XIic *InstancePtr, int AddressType);

int XIic_SetGpOutput(XIic *InstancePtr, u8 OutputValue);
int XIic_GetGpOutput(XIic *InstancePtr, u8 *OutputValuePtr);

u32 XIic_IsSlave(XIic *InstancePtr);

void XIic_SetRecvHandler(XIic *InstancePtr, void *CallBackRef,
			 XIic_Handler FuncPtr);
void XIic_SetSendHandler(XIic *InstancePtr, void *CallBackRef,
			 XIic_Handler FuncPtr);
void XIic_SetStatusHandler(XIic *InstancePtr, void *CallBackRef,
			   XIic_StatusHandler FuncPtr);

/*
 * Interrupt functions in xiic_intr.c
 */
void XIic_InterruptHandler(void *InstancePtr);

/*
 * Master send and receive functions in normal mode in xiic_master.c
 */
int XIic_MasterRecv(XIic *InstancePtr, u8 *RxMsgPtr, int ByteCount);
int XIic_MasterSend(XIic *InstancePtr, u8 *TxMsgPtr, int ByteCount);

/*
 * Master send and receive functions in dynamic mode in xiic_master.c
 */
int XIic_DynMasterRecv(XIic *InstancePtr, u8 *RxMsgPtr, u8 ByteCount);
int XIic_DynMasterSend(XIic *InstancePtr, u8 *TxMsgPtr, u8 ByteCount);

/*
 * Dynamic IIC Core Initialization.
 */
int XIic_DynamicInitialize(XIic *InstancePtr);

/*
 * Slave send and receive functions in xiic_slave.c
 */
void XIic_SlaveInclude(void);
int XIic_SlaveRecv(XIic *InstancePtr, u8 *RxMsgPtr, int ByteCount);
int XIic_SlaveSend(XIic *InstancePtr, u8 *TxMsgPtr, int ByteCount);

/*
 * Statistics functions in xiic_stats.c
 */
void XIic_GetStats(XIic *InstancePtr, XIicStats *StatsPtr);
void XIic_ClearStats(XIic *InstancePtr);

/*
 * Self test functions in xiic_selftest.c
 */
int XIic_SelfTest(XIic *InstancePtr);

/*
 * Bus busy Function in xiic.c
 */
u32 XIic_IsIicBusy(XIic *InstancePtr);

/*
 * Options functions in xiic_options.c
 */
void XIic_SetOptions(XIic *InstancePtr, u32 Options);
u32 XIic_GetOptions(XIic *InstancePtr);

/*
 * Multi-master functions in xiic_multi_master.c
 */
void XIic_MultiMasterInclude(void);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
/** @} */
