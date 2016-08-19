#include "libxlnk_cma.h"

void *cma_alloc(uint32_t len, uint32_t cacheable){
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

    if (len <= 0)
        return NULL;

    uint32_t bufId = 0;
    uint32_t bufPhyAddr = 0;
    void *addr;
    xlnk_args xlnkArgs;
    xlnkArgs.allocbuf.len = len;
    xlnkArgs.allocbuf.idptr = &bufId;
    xlnkArgs.allocbuf.phyaddrptr = &bufPhyAddr;
    xlnkArgs.allocbuf.cacheable = cacheable;

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
    close(fd);
    return addr;
}

static int findBuf(void *buf, uint32_t *offset)
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

uint32_t cma_get_phy_addr(void *buf){
    uint32_t offset;
    int bufId = findBuf(buf, &offset);
    if (bufId < 0) 
        return -1;
    return xlnkBufPhyPool[bufId] + offset;
}

void cma_free(void *buf){
    if (xlnkBufCnt == 0)
        return;

    int fd = open(XLNK_DRIVER_PATH, O_RDWR);
    if (fd < 0)
        printf("unable to open %s\n", XLNK_DRIVER_PATH); 

    int bufId = 0;
    xlnk_args xlnkArgs;
    uint32_t offset;
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

uint32_t cma_mmap(uint32_t phyAddr, uint32_t len)
{
   uint32_t * addr;int fd,pa_offset;
   pa_offset = phyAddr & ~(sysconf(_SC_PAGE_SIZE) - 1);
   fd = open("/dev/mem", O_RDWR); 
    addr = mmap(NULL, len, PROT_READ | PROT_WRITE,
            MAP_SHARED, fd, pa_offset);
    if (addr == MAP_FAILED) {
        printf("mmap failed.\n");
        return -1;
    }
    return (uint32_t) addr;
}

uint32_t cma_munmap(void *buf, uint32_t len)
{
    return munmap(buf, len);
}

void xlnkFlushCache(void *buf, int size)
{
    int fd = open(XLNK_DRIVER_PATH, O_RDWR);
    if (fd < 0){  
        printf("unable to open %s\n", XLNK_DRIVER_PATH);
        return;
    }

    int ioctl_status;
    xlnk_args ccargs;
    ccargs.cachecontrol.phys_addr = buf;
    ccargs.cachecontrol.size = size;
    ccargs.cachecontrol.action = 0;

    ioctl_status = ioctl(fd, XLNK_IOCCACHECTRL, &ccargs);
    if (ioctl_status < 0)
    {
        printf("ERROR: ioctl_status = %d Failed to flush cache\n", ioctl_status);
    }
}

void xlnkInvalidateCache(void *buf, int size)
{
    int fd = open(XLNK_DRIVER_PATH, O_RDWR);
    if (fd < 0){  
        printf("unable to open %s\n", XLNK_DRIVER_PATH);
        return;
    }
    int ioctl_status;
    xlnk_args ccargs;
    ccargs.cachecontrol.phys_addr = buf;
    ccargs.cachecontrol.size = size;
    ccargs.cachecontrol.action = 1;

    ioctl_status = ioctl(fd, XLNK_IOCCACHECTRL, &ccargs);
    if (ioctl_status < 0)
    {
        printf("ERROR: ioctl_status = %d Failed to invalidate cache\n", ioctl_status);
    }
}
