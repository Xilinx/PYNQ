#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// kernel buffer pool
#define XLNK_BUFPOOL_SIZE 100

#define XLNK_DRIVER_PATH "/dev/xlnk"

// counter of buffer currently instantiated
static uint32_t xlnkBufCnt = 0;
// virtual address of buffer
static void *xlnkBufPool[2 * XLNK_BUFPOOL_SIZE];
// length in bytes of buffer
static size_t xlnkBufLens[2 * XLNK_BUFPOOL_SIZE];
// physical address of buffer
static uint32_t xlnkBufPhyPool[2 * XLNK_BUFPOOL_SIZE];

/*
 * Get the virtual address referencing the physical address resulting from
 * mmaping /dev/mem.
 * Required to use bare-metal drivers on linux. Return -1 in case of error.
 */
unsigned long cma_mmap(unsigned long phyAddr, uint32_t len);
/*
 * Unmap a previously mapped memory space.
 */
uint32_t cma_munmap(void *buf, uint32_t len);
/*
 * Allocate a physically contiguos chunk of CMA memory and map it into
 * virtual memory space. Return this Virtual pointer. Returns -1 on failure.
 */
void *cma_alloc(uint32_t len, uint32_t cacheable);
/*
 * Return a physical memory address corresponding to a given Virtual address
 * pointer. Returns NULL on failure.
 */
unsigned long cma_get_phy_addr(void *buf);
/*
 * Free a previously allocated CMA memory chunk.
 */
void cma_free(void *buf);
/*
 * Returns the number of available CMA memiry pages which can be allocated.
 */
uint32_t cma_pages_available();
/*
 * Extra functions in case user needs to flush or invalidate Cache.
 */
void cma_flush_cache(void *buf, unsigned int phys_addr, int size);
void cma_invalidate_cache(void *buf, unsigned int phys_addr, int size);
