/*
 * Functions to interact with linux gpio. No safe checks here, users must
 * know what they are doing.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "gpio.h"

int setGpio(unsigned int index, const char *direction){
    int fd;
    char buf[50];
    sprintf(buf, "/sys/class/gpio/gpio%d/direction", index);          
    if(access(buf, F_OK) != -1)
        unsetGpio(index);
    if((fd = open("/sys/class/gpio/export", O_WRONLY)) == -1)
        return -1;
    sprintf(buf, "%d", index);   
    if(write(fd, buf, strlen(buf)) == -1)
        return -1;
    close(fd);  
    
    sprintf(buf, "/sys/class/gpio/gpio%d/direction", index);       
    if((fd = open(buf, O_WRONLY)) == -1)
        return -1;        
    if(write(fd, direction, strlen(direction)) == -1)
        return -1;
    close(fd);
    return 0;
}

int unsetGpio(unsigned int index){
    int fd;
    char buf[50];
    if((fd = open("/sys/class/gpio/unexport", O_WRONLY)) == -1)
        return -1;
    sprintf(buf, "%d", index);   
    if(write(fd, buf, strlen(buf)))
        return -1;
    close(fd);
    return 0;    
}

int writeGpio(unsigned int index, int value){
    int fd;
    char buf[50];
    sprintf(buf, "/sys/class/gpio/gpio%d/value", index);   
    if((fd = open(buf, O_WRONLY)) == -1)
        return -1;
    sprintf(buf, "%d", value);
    if(write(fd, buf, strlen(buf)) == -1)
        return -1;
    close(fd);
    return 0;       
}

int readGpio(unsigned int index){
    int fd;
    char buf[50];
    sprintf(buf, "/sys/class/gpio/gpio%d/value", index);   
    if((fd = open(buf, O_RDONLY)) == -1)
        return -1;
    if(read(fd, buf, 10) == -1)
        return -1;
    close(fd);
    return atoi(buf); 
}
