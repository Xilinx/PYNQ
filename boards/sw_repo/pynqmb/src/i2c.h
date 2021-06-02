/******************************************************************************
 *  Copyright (c) 2018, Xilinx, Inc.
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
 * @file i2c.h
 *
 * Header file for I2C related functions for PYNQ Microblaze, 
 * including the IIC read and write.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq 01/09/18 release
 * 1.01  yrq 01/30/18 add protection macro
 *
 * </pre>
 *
 *****************************************************************************/
#ifndef _I2C_H_
#define _I2C_H_
#ifdef __cplusplus 
extern "C" {
#endif
#include <xparameters.h>
#include <pytypes.h>

#ifdef XPAR_XIIC_NUM_INSTANCES
#define PYNQ_HAS_I2C

/* 
 * Microblaze IIC Interface
 *
 * Implements low-level functions for read and writing to I2C slaves.
 * The main comonents of the API are `i2c_read` and `i2c_write` which
 * transfer a fixed number of bytes over the I2C bus. See the function
 * documentation for more details.
 *
 * To create an I2C instace use `i2c_open` or `i2c_open_device`
 *
 */
typedef py_int i2c;

/** Open an I2C hardware instance
 *
 * Opens an I2C with the specified instance ID. This will be
 * IOP specific and can be found in the documentation for the IOP
 * or in the SDK project used to generate the BSP
 *
 * Parameters
 * ----------
 * device : int
 *     The index of the device to open
 *
 * Returns
 * -------
 *     An I2C object
 *
 */
i2c i2c_open_device(unsigned int device);

#ifdef XPAR_IO_SWITCH_NUM_INSTANCES
#ifdef XPAR_IO_SWITCH_0_I2C0_BASEADDR
/** Open an I2C device through an IO switch
 *
 * Parameters
 * ----------
 * sda : int
 *     The data pin number on the IO switch
 * scl : int
 *     The clock pin number on the IO switch
 *
 * Returns
 * -------
 *     An I2C object
 */
i2c i2c_open(unsigned int sda, unsigned int scl);
#endif
#endif

/** Read from the I2C Bus
 *
 * Reads a fixed number of bytes from the I2C bus
 *
 * Parameters
 * ----------
 * slave_address : int
 *     The address of the slave to read from
 * buffer : bytearray
 *     A writeable buffer object to read the bytes into
 * length : int
 *     The number of bytes to read
 *
 * Returns
 * -------
 *     int : The number of bytes read - can be 0 on an error
 *
 */
py_int i2c_read(i2c dev_id, unsigned int slave_address,
              unsigned char* buffer, unsigned int length);

/** Write to the I2C Bus
 *
 * Writes a fixed number of bytes to the I2C bus
 *
 * Parameters
 * ----------
 * slave_address : int
 *     The address of the slave to read from
 * buffer : bytes
 *     A buffer object containing the bytes to write
 * length : int
 *     The number of bytes to write
 *
 * Returns
 * -------
 *     int : The number of bytes read - can be 0 on an error
 *
 */
py_int i2c_write(i2c dev_id, unsigned int slave_address,
               unsigned char* buffer, unsigned int length);

/** Close an I2C Device
 *
 * `read` and `write` should not be called on the device once
 * it is closed
 */
void i2c_close(i2c dev_id);

/** Returns the number of I2C controllers in the IOP
 *
 * The value passed to `i2c_open` should be less than this number
 */
unsigned int i2c_get_num_devices(void);

#endif
#ifdef __cplusplus 
}
#endif
#endif  // _I2C_H_
