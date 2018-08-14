#define _GNU_SOURCE

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "libxlnk_cma.h"
#include <linux/ioctl.h>
#include <errno.h>
#include <dlfcn.h>

#define RESET_IOCTL _IOWR('X', 101, unsigned long)

/* Function prototypes from sdslib */
void *sds_alloc_cacheable(uint32_t len);
void *sds_alloc_non_cacheable(uint32_t len);
void sds_free(void*);
void *sds_mmap(void *phy_addr, size_t size, void *virtual_addr);
void sds_munmap(void *virtal_addr);


/* Functional prototpes from xlnk */

unsigned long xlnkGetBufPhyAddr(void*);
extern void xlnkFlushCache(unsigned int phys_addr, int size);
extern void xlnkInvalidateCache(unsigned int phys_addr, int size);

/* Required to avoid undefined symbol error */
void add_sw_estimates(void) {}


/* CMA implementations */
uint32_t cma_pages_available(void)
{
    FILE * fp;
    char * line = NULL;
    size_t len = 0;
    ssize_t read;
    char * cmp = "nr_free_cma";
    char dummy[20];
    int num = -1;

    fp = fopen("/proc/vmstat", "r");
    if (fp == NULL)
        return -1 ;

    while ((read = getline(&line, &len, fp)) != -1) {
        if (strstr(line,cmp) !=NULL) {
            sscanf(line,"%s %d",dummy,&num);
        }
    }
    fclose(fp);
    return num;
}

unsigned long cma_mmap(unsigned long phyAddr, uint32_t len) {
    return (unsigned long)sds_mmap((void*)phyAddr, len, NULL);
}

uint32_t cma_munmap(void* buf, uint32_t len) {
    sds_munmap(buf);
    return 0;
}

void *cma_alloc(uint32_t len, uint32_t cacheable) {
    if (cacheable) {
        return sds_alloc_cacheable(len);
    } else {
        return sds_alloc_non_cacheable(len);
    }
}

unsigned long cma_get_phy_addr(void *buf) {
    return xlnkGetBufPhyAddr(buf);
}

void cma_free(void *buf) {
    return sds_free(buf);
}

void _xlnk_reset() {
    /* This performs the correct ioctl but probably isn't
       particularly stable as a behaviour */
    int xlnkfd = open("/dev/xlnk", O_RDWR | O_CLOEXEC);
    if (xlnkfd < 0) {
        printf("Reset failed - could not open device: %d\n", xlnkfd);
        return;
    }
    if (ioctl(xlnkfd, RESET_IOCTL, 0) < 0) {
        printf("Reset failed - IOCTL failed: %d\n", errno);
    }
    close(xlnkfd);
}


void cma_flush_cache(void* buf, unsigned int phys_addr, int size) {
#ifdef __aarch64__
    uintptr_t begin = (uintptr_t)buf;
    uintptr_t line = begin &~0x3FULL;
    uintptr_t end = begin + size;

    uintptr_t stride = 64; // TODO: Make this architecture dependent

    asm volatile(
    "loop:\n\t"
    "dc civac, %[line]\n\t"
    "add %[line], %[line], %[stride]\n\t"
    "cmp %[line], %[end]\n\t"
    "b.lt loop\n\t"
    ::[line] "r" (line),
    [stride] "r" (stride),
    [end] "r" (end)
    : "cc", "memory"
    );
#else
    xlnkFlushCache(phys_addr, size);
#endif
}

void cma_invalidate_cache(void* buf, unsigned int phys_addr, int size) {
#ifdef __aarch64__
    cma_flush_cache(buf, phys_addr, size);
#else
    xlnkInvalidateCache(phys_addr, size);
#endif
}
