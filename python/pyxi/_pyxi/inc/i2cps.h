/*
 * Functions to interact with linux i2c. No safe checks here, users must
 * know what they are doing.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   03 FEB 2016
 */

#ifndef __I2CPS_H__
#define __I2CPS_H__

#include <linux/i2c-dev.h> // NOTE: need package libi2c-dev to be installed

int setI2C(unsigned int index, long slave_addr);
int unsetI2C(int i2c_fd);
int writeI2C_asFile(int i2c_fd, unsigned char writebuffer[], 
                    unsigned char bytes);
int readI2C_asFile(int i2c_fd, unsigned char readbuffer[], 
                   unsigned char bytes);

#define writeI2C_byte(i2c_fd, u8RegAddr, u8Data) \
                      i2c_smbus_write_byte_data(i2c_fd, u8RegAddr, u8Data);

#define writeI2C_word(i2c_fd, u8RegAddr, u16Data) \
                      i2c_smbus_write_word_data(i2c_fd, u8RegAddr, u16Data);

#endif // __I2CPS_H__