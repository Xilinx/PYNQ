/*
 * some hooks to /dev/xlnk (drivers/staging/apf in kernel src)
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   11 FEB 2016
 */

#include "utils.h"
#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "xlnk-ioctl.h"
#include "xlnk-os.h"
#include <sys/ioctl.h>

#define XLNK_DRIVER_PATH "/dev/xlnk"

// kernel buffer pool
#define XLNK_BUFPOOL_SIZE 100
// counter of buffer currently instantiated
static unsigned int xlnkBufCnt = 0;
// virtual address of buffer
static void *xlnkBufPool[2 * XLNK_BUFPOOL_SIZE];
// length in bytes of buffer
static size_t xlnkBufLens[2 * XLNK_BUFPOOL_SIZE];
// physical address of buffer
static unsigned int xlnkBufPhyPool[2 * XLNK_BUFPOOL_SIZE];

void *frame_alloc(size_t len){
    if(xlnkBufCnt == XLNK_BUFPOOL_SIZE){
        printf("Buffer pool size exceeded.\n");
        return NULL;
    }

    int fd = open(XLNK_DRIVER_PATH, O_RDWR);
    if (fd < 0){  
        printf("unable to open %s\n", XLNK_DRIVER_PATH);
        return NULL;
    }  

    if(xlnkBufCnt == 0){
        xlnk_args xlnkArgs;
        ioctl(fd, XLNK_IOCRECRES, &xlnkArgs);
        ioctl(fd, XLNK_IOCRESET, &xlnkArgs);
    }

    if (len == 0)
        return NULL;

    unsigned int bufId = 0;
    unsigned int bufPhyAddr = 0;
    void *addr;
    xlnk_args xlnkArgs;
    xlnkArgs.allocbuf.len = len;
    xlnkArgs.allocbuf.idptr = &bufId;
    xlnkArgs.allocbuf.phyaddrptr = &bufPhyAddr;
    xlnkArgs.allocbuf.cacheable = 0;

    int err = ioctl(fd, XLNK_IOCALLOCBUF, &xlnkArgs);
    if (err) {
        printf("XLNK_IOCALLOCBUF ioctl returned %d.\n", err);
        return NULL;
    }
    if (!bufId) {
        printf("buf ID = 0\n");
        return NULL;
    }
    addr = mmap(NULL, len, PROT_READ | PROT_WRITE,
            MAP_SHARED | MAP_LOCKED, fd, bufId << 24);
    if (addr == NULL) {
        printf("buffer mmap failed.\n");
        return NULL;
    }
    xlnkBufPool[bufId] = addr;
    xlnkBufLens[bufId] = len;
    xlnkBufPhyPool[bufId] = bufPhyAddr;
    xlnkBufCnt++;

    err = close(fd);
    if(err < 0){
        printf("error while closing %s\n", XLNK_DRIVER_PATH);
    }

    return addr;
}

static int findBuf(void *buf, unsigned int *offset)
{
    if (!buf || !offset)
        return -1;

    for (int i = 0; i < (2 * XLNK_BUFPOOL_SIZE); i++) {
        if((xlnkBufPool[i] <= buf) && (buf < xlnkBufPool[i] + xlnkBufLens[i])) {
            *offset = buf - xlnkBufPool[i];
            return i;
        }
    }

    *offset = 0;
    return -1;
}

unsigned int frame_getPhyAddr(void *buf){
    unsigned int offset;
    int bufId = findBuf(buf, &offset);
    if (bufId < 0) 
        return 0;
    return xlnkBufPhyPool[bufId] + offset;
}

void frame_free(void *buf){
    if (xlnkBufCnt == 0)
        return;

    int fd = open(XLNK_DRIVER_PATH, O_RDWR);
    if (fd < 0)
        printf("unable to open %s\n", XLNK_DRIVER_PATH); 

    int bufId = 0;
    xlnk_args xlnkArgs;
    unsigned int offset;
    bufId = findBuf(buf, &offset);

    if (bufId <= 0 || offset > 0)
        return;

    xlnkArgs.freebuf.id = bufId;
    xlnkArgs.freebuf.buf = buf;

    munmap(buf, xlnkBufLens[bufId]);
    ioctl(fd, XLNK_IOCFREEBUF, &xlnkArgs);
    xlnkBufPool[bufId] = NULL;
    xlnkBufLens[bufId] = 0;
    xlnkBufPhyPool[bufId] = 0;
    xlnkBufCnt--;

    if(xlnkBufCnt == 0)
        ioctl(fd, XLNK_IOCSHUTDOWN, &xlnkArgs);       

    int err = close(fd);
    if(err < 0)
        printf("error while closing %s\n", XLNK_DRIVER_PATH);
}
