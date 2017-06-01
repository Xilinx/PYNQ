#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "libxlnk_cma.h"

/* Function prototypes from sdslib */
void *sds_alloc_cacheable(uint32_t len);
void *sds_alloc_non_cacheable(uint32_t len);
void sds_free(void*);
void *sds_mmap(void *phy_addr, size_t size, void *virtual_addr);
void sds_munmap(void *virtal_addr);

/* CF helper functions */
void cf_xlnk_open(int last);
void cf_xlnk_init(int arg);

/* Functional prototpes from xlnk */

unsigned long xlnkGetBufPhyAddr(void*);

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
    cf_xlnk_init(1);
}

/* Constructor to Open xlnk device */

__attribute__((constructor))
void open_xlnk(void) {
    cf_xlnk_open(1);
}

