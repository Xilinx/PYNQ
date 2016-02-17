/*
 * Functions to interact with linux i2c. No safe checks here, users must
 * know what they are doing.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   03 FEB 2016
 */

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "i2cps.h"

int setI2C(unsigned int index, long slave_addr){
    int i2c_fd;
    char buf[50];
    sprintf(buf, "/dev/i2c-%d", index);          
    if((i2c_fd = open(buf, O_RDWR)) < 0)
        return -1;
    if (ioctl(i2c_fd, I2C_SLAVE, slave_addr) < 0)
        return -1;
    return i2c_fd;
}

int unsetI2C(int i2c_fd){
    close(i2c_fd);
    return 0;    
}

int writeI2C_asFile(int i2c_fd, unsigned char writebuffer[], 
                    unsigned char bytes){
    unsigned char bytesWritten = write(i2c_fd, writebuffer, bytes);
    if(bytes != bytesWritten)
        return -1;
    return 0;
}

int readI2C_asFile(int i2c_fd, unsigned char readbuffer[], 
                   unsigned char bytes){
    unsigned char bytesRead = read(i2c_fd, readbuffer, bytes);
    if(bytes != bytesRead)
        return -1;
    return 0;
}