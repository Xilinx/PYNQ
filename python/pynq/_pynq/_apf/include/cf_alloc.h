#ifndef CF_ALLOC_H
#define CF_ALLOC_H

#ifdef __cplusplus
extern "C" {
#endif

struct cf_alloc_attr_struct {
	int cacheable; /* 0 - non-cacheable, use with AFI only; 1 - cacheable, use with ACP only */
        int  physical_addr;
};

void cf_free(void *memptr);

void cf_set_mem_attr(cf_port_base_t *port, int attr);

extern void *cf_alloc(
  size_t size,
  cf_alloc_attr_t *attr);

extern void *cf_mmap(
  void *physicalAddr,
  size_t size,
  void *virtualAddr);

extern void cf_munmap(
  void *virtualAddr);

#ifdef __cplusplus
};
#endif

#endif

