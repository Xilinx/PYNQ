/*
 * Functions to interact with linux gpio. No safe checks here, users must
 * know what they are doing.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#ifndef __GPIO_H__
#define __GPIO_H__

int setGpio(unsigned int index, const char *direction);

int unsetGpio(unsigned int index);

int writeGpio(unsigned int index, int value);

int readGpio(unsigned int index);

#endif // __GPIO_H__
