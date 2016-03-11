/*
 * - Implementation of a dynamic array that can only grow in size.
 * The dynamic array is a modified version of:
 * http://stackoverflow.com/questions/3536153/c-dynamically-growing-array
 *
 * - Helper function to get the /dev/mem mmap-ed address of a given
 * physical address.
 *
 * - Helper function to get an unsigned integer from a python dictionary
 * given a string as key
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#ifndef __UTILS_H__
#define __UTILS_H__

#include <Python.h>

typedef int *ptr;

typedef struct {
  ptr *array;
  int *refCnt;
  size_t used;
  size_t size;
} Array;

void initArray(Array *a, size_t initialSize);

void appendElemArray(Array *a, ptr elem);

void freeArray(Array *a);


/*
 * Get the virtual address referencing the physical address resulting from
 * mmap-ing /dev/mem
 * Required to use bare-metal drivers on linux. Return NULL in case of error.
 */
unsigned int getVirtualAddress(unsigned int phy_addr);
unsigned int getVirtualAddress_size(unsigned int phy_addr, unsigned int map_size);
void freeVirtualAddress(unsigned int virt_addr);
void freeVirtualAddress_size(unsigned int phy_addr, unsigned int map_size);

/*
 * Return an unsigned integer value from a dictionary, using a string as key.
 * This function assumes correctness of the input dictionary and existence
 * of the key in the dictionary.
 */
#define PyDict_GetUintString(dict,key) \
        ((unsigned int)PyLong_AsUnsignedLong(PyDict_GetItemString(dict, key)))


void *frame_alloc(size_t len);
unsigned int frame_getPhyAddr(void *buf);
void frame_free(void *buf);

#endif // __UTILS_H__
