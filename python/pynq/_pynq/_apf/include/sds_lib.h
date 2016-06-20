#ifndef D_sds_lib
#define D_sds_lib


#ifdef __cplusplus
extern "C" {
#endif
/* wait for the first request list in the queue identified by id, to complete */
extern void sds_wait( unsigned int id);

/* allocate a physically contiguous array of size bytes for DMA transfers */
extern void *sds_alloc( size_t size);

/* allocate a physically contiguous array of size bytes for DMA transfers.
   Same as sds_alloc() */
extern void *sds_alloc_cacheable( size_t size);

/* allocate a physically contiguous array of size bytes for DMA transfers, but
   mark the pages as non-cacheable */
extern void *sds_alloc_non_cacheable( size_t size);

/* free an array allocated through sds_alloc */
extern void sds_free(void *memptr);

/* Create a virtual address mapping to access a memory of size size bytes located at physical address physical_addr
 physical_addr: physical address to be mapped
          size: size of physical address to be mapped
  virtual_addr: If a non-null value is passed in, it is considered to be 
                the virtual-address already mapped to the physical_addr, and cf_mmap keeps track of the mapping
                If a null value is passed in, cf_mmap invokes mmap() to generate the virtual address, and 
                virtual_addr is assigned this value */
extern void *sds_mmap( void *physical_addr, size_t size, void *virtual_addr);

/* register a handle between a given userspace virtual address and an FD that
   corresponds to a handle to a GEM-allocated buffer */  
extern int sds_register_dmabuf(void *virtual_addr, int fd);
  
/* unregister a handle between a given userspace virtual address and an FD that
   corresponds to a handle to a GEM-allocated buffer that was previously
   registered by using sds_register_dmabuf() */  
extern int sds_unregister_dmabuf(void *virtual_addr, int fd);
  
/* unmaps a virtual address mapped associated with a physical address using sds_mmap() */
extern void sds_munmap( void *virtual_addr);

/* returns the value associated with a free-running counter used for fine grain time-interval measurements
   The counter increments on every processor clock, and wraps to 0 */
extern unsigned long long sds_clock_counter(void);

/* 32 bit version of sds_clock_counter() */
extern unsigned long sds_clock_counter32(void);

/* stops the global counter, sets the global counter to the given value, then starts it running again from the given value */
extern void sds_set_counter(unsigned long long val);

/* do not use - this is for internal use only, and will be removed from this header */
/* function called by automatically generated stub code to insert a handle onto a queue 
   The user then calls sds_wait with the same id to wait for the request to complete
   paramters: id: queue ID
              req: opaque pointer to a request list allocated by the function
	      num: number of items in the request list
*/
extern void sds_insert_req( unsigned int id, void *req, int num);

/* Trace Event Types */
#define EVENT_START 0x04
#define EVENT_STOP 0x05

#ifdef __cplusplus
}
#endif
  
#endif /* D_sds_lib */


