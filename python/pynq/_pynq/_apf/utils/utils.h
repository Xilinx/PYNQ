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

typedef int *ptr;

/*
 * Get the virtual address referencing the physical address resulting from
 * mmap-ing /dev/mem
 * Required to use bare-metal drivers on linux. Return NULL in case of error.
 */
unsigned int getVirtualAddress(unsigned int phy_addr);
unsigned int getVirtualAddress_size(unsigned int phy_addr, unsigned int map_size);
void freeVirtualAddress(unsigned int virt_addr);
void freeVirtualAddress_size(unsigned int phy_addr, unsigned int map_size);
unsigned int getMemoryMap(unsigned int phyAddr, unsigned int len);

void *frame_alloc(unsigned int len);
unsigned int getPhyAddr(void *buf);
void frame_free(void *buf);
