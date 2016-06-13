#include "axi_dma_simple_dm.h"
#include "dmadefs.h"

extern "C" void custom_dma_register(int id);
extern "C" void custom_dma_unregister(int id);

extern "C" int custom_dma_open(
	axi_dma_simple_channel_info_t * dstruct, int id
	);
extern "C" int custom_dma_close(
	axi_dma_simple_channel_info_t * dstruct, int id
	);

extern "C" int custom_dma_send_i(
	axi_dma_simple_channel_info_t * dstruct, 
	void *buf, size_t len,int id
	);
extern "C" int custom_dma_recv_i(
	axi_dma_simple_channel_info_t * dstruct, 
	void *buf, size_t len,size_t *num_recd,int id
	);

extern "C" void custom_dma_wait(int id);
