#ifndef AXI_DMA_SIMPLE_DM_H
#define AXI_DMA_SIMPLE_DM_H

#include "cf_lib.h"

#ifdef __cplusplus
extern "C" {
#endif

struct axi_dma_simple_info_struct {
	int device_id;
	int phys_base_addr;
	int addr_range;
	int virt_base_addr;
	int dir; // either DMA_TO_DEV or DMA_FROM_DEV 
};
typedef struct axi_dma_simple_info_struct axi_dma_simple_info_t;

struct axi_dma_simple_channel_info_struct {
		axi_dma_simple_info_t *dma_info;
		int in_use;
		int needs_cache_flush_invalidate;
};
typedef struct axi_dma_simple_channel_info_struct axi_dma_simple_channel_info_t;

void axi_dma_simple_register (void *info);
void axi_dma_simple_unregister (void *info);
void axi_dma_simple_wait (void *info);

int axi_dma_simple_open (cf_port_base_t *port, cf_request_handle_t *request);
int axi_dma_simple_close (cf_port_base_t *port, cf_request_handle_t *request);


int axi_dma_simple_send_ref_i (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int axi_dma_simple_send_i (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int axi_dma_simple_recv_i (cf_port_receive_t *port,
		void *buf,
		size_t len,
		size_t *num_recd,
		cf_request_handle_t *request);

int axi_dma_simple_recv_ref_i (cf_port_receive_t *port,
		void **buf,
		size_t *len,
		cf_request_handle_t *request);



#ifdef __cplusplus
};
#endif

#endif

