import cffi
ffi = cffi.FFI()
#wa = ffi.new_handle("struct test")

DMA_TO_DEV = 0
DMA_FROM_DEV = 1
device_id = 0
DMA_ADDR_RANGE = 0x10000

ffi.cdef("""
typedef struct axi_dma_simple_info_struct {
        int device_id;
        int phys_base_addr;
        int addr_range;
        int virt_base_addr;
        int dir; // either DMA_TO_DEV or DMA_FROM_DEV 
} axi_dma_simple_info_t;
""")

ffi.cdef("""
typedef struct axi_dma_simple_channel_info_struct {
                axi_dma_simple_info_t *dma_info;
                int in_use;
                int needs_cache_flush_invalidate;
} axi_dma_simple_channel_info_t;
""")

ffi.cdef("""
void custom_dma_register(int id);
""")

ffi.cdef("""
void custom_dma_unregister(int id);
""")

ffi.cdef("""
int custom_dma_open(
        axi_dma_simple_channel_info_t * dstruct, int id
        );
""")

ffi.cdef("""
int custom_dma_close(
        axi_dma_simple_channel_info_t * dstruct, int id
        );
""")

ffi.cdef("""
int custom_dma_send_i(
        axi_dma_simple_channel_info_t * dstruct,
        void *buf, int len,int id
        );

""")

ffi.cdef("""
int custom_dma_recv_i(
        axi_dma_simple_channel_info_t * dstruct,
        void *buf, int len,int *num_recd,int id
        );
""")

ffi.cdef("""
void custom_dma_wait(int id);
""")

dmalib = ffi.dlopen("/home/xpp/dma/libdma.so")
