#ifndef XLNK_CORE_CF_H
#define XLNK_CORE_CF_H
#ifdef __cplusplus
extern "C" {
#endif

// the following are for xlnkDMARegister
#define	XLNK_DMA_TO_DEV  0
#define	XLNK_DMA_FROM_DEV  1
#define XLNK_BI_DIRECTIONAL  2
// the following are from xlnk-os.h (but the DMA_TO and DMA_FROM flags are not
#define XLNK_FLAG_COHERENT  		0x00000001
#define XLNK_FLAG_KERNEL_BUFFER		0x00000002
#define XLNK_FLAG_DMAPOLLING		0x00000004
#define XLNK_FLAG_PHYSICAL_ADDR		0x00000100
#define XLNK_FLAG_VIRTUAL_ADDR		0x00000200

#define CF_FLAG_CACHE_FLUSH_INVALIDATE 0x00000001
#define CF_FLAG_PHYSICALLY_CONTIGUOUS  0x00000002
#define CF_FLAG_DMAPOLLING             0x00000004

typedef unsigned int xlnk_handle_t;

extern void *xlnkAllocBufInternal(size_t len, int cacheable);
extern void *xlnk_mmap2(void *phy_addr, unsigned int size, void *virt_addr);
extern void xlnk_munmap2(void *buf);
extern int xlnk_munmap(unsigned int virt_addr, unsigned int size);
extern void *xlnkAllocBuf(size_t len);
extern void xlnkFreeBuf(void *buf);
extern unsigned int xlnkGetBufPhyAddr(void *buf);
extern unsigned int xlnkGetBufPhyAddrAndCacheable(void *buf, int *cacheable);
extern void xlnkFlushCache(void *buf, int size);
extern void xlnkInvalidateCache(void *addr, int size);

	
extern int xlnkDMARequest(char *name, xlnk_handle_t *dmachan);
extern int xlnkDMARelease(xlnk_handle_t dmachan);
extern int xlnkDMASubmit(xlnk_handle_t dmachan,
	void *buf, 
	unsigned int len,
	unsigned int dmadir,
	unsigned int nappwords_i,
	unsigned int *appwords_i,
	unsigned int nappwords_o,
	unsigned int flag,
	xlnk_handle_t *dmahandle);
extern int xlnkDMAWait(xlnk_handle_t dmahandle,
	unsigned int nappwords_o,
	unsigned int *appwords_o);
extern int xlnkDmaRegister(char *name,
	unsigned int id,
	unsigned long base,
	unsigned int size,
	unsigned int chan_num,
	unsigned int chan0_dir,
	unsigned int chan0_irq,
	unsigned int chan0_poll_mode,
	unsigned int chan0_include_dre,
	unsigned int chan0_data_width,
	unsigned int chan1_dir,
	unsigned int chan1_irq,
	unsigned int chan1_poll_mode,
	unsigned int chan1_include_dre,
	unsigned int chan1_data_width);
extern void xlnkDmaUnregister(unsigned long base);
extern int xlnkDevRegister(char *name,
	unsigned int id,
	unsigned long base,
	unsigned int size,
	unsigned int irq0,
	unsigned int irq1,
	unsigned int irq2,
	unsigned int irq3);
void xlnkDevUnregister(unsigned long base);

// return 0 if device registration has to be done, 1 if device registration has been done already and <0 for error
int cf_xlnk_open(int);
// second half of xlnkOpen, to be called after device registration if cfXlnkOpen returns 1
void cf_xlnk_init(int);

void xlnkClose(int, void *);
unsigned int xlnkUioMap(int uio_id, unsigned int phys_base, unsigned int addr_range);
void xlnkUioUnMap(unsigned int virt_base, unsigned int addr_range);
void xlnkUioWrite32(void *base, unsigned int offset, unsigned int data);
unsigned int xlnkUioRead32(void *base, unsigned int offset);
unsigned long xlnkGetGlobalCounter(void);
unsigned long long xlnkGetGlobalCounter64(void);
void xlnkSetGlobalCounter(unsigned long long val);

#ifdef __cplusplus
};
#endif
#endif

