#ifndef AXI_DMA_2D_DM_H
#define AXI_DMA_2D_DM_H

#include "cf_lib.h"

#ifdef __cplusplus
extern "C" {
#endif
struct axi_dma_2d_bd_struct {
        unsigned int next_desc_ptr; // 31:6 -> ptr, 5:0 -> reserved
        unsigned int reserved1;
        unsigned int buffer_addr;
        unsigned int reserved2;
        unsigned int attr_bytes; // 31:28 -> ARUSER, 27:24 -> ARCACHE; TX ONLY -> 19:16 -> TUSER, 12:8 -> TID, 4:0 -> TDEST
        unsigned int vsize_stride; // 31:19->Vsize, 15:0 -> stride
        unsigned int ctrl_hsize; // 27 -> SOP, 26 -> EOP, 15:0 -> Hsize
        unsigned int status; // 31 -> Cmp, 30 -> DE, 29 -> SE, 28-> IE; RX ONLY -> 27->SOP, 26->EOP, 19:16 -> TUSER, 12:8->TID, 4:0->TDEST
};

struct axi_dma_2d_info_struct {
	int device_id;
	int phys_base_addr;
	int addr_range;
	int intr_num;
	int uio_fd;
	int virt_base_addr;
	int dir; // either DMA_TO_DEV or DMA_FROM_DEV 
	struct axi_dma_2d_bd_struct *bd_head;
	struct axi_dma_2d_bd_struct *bd_tail;
	struct axi_dma_2d_bd_struct *current_bd;
	unsigned int bd_head_phy;
	unsigned int bd_tail_phy;
	unsigned int current_bd_phy;
	int first_op;
};
typedef struct axi_dma_2d_info_struct axi_dma_2d_info_t;

struct axi_dma_2d_channel_info_struct {
		axi_dma_2d_info_t *dma_info;
		int in_use;
		int needs_cache_flush_invalidate;
};
typedef struct axi_dma_2d_channel_info_struct axi_dma_2d_channel_info_t;

void axi_dma_2d_register (void *info);
void axi_dma_2d_unregister (void *info);

int axi_dma_2d_open (cf_port_base_t *port, cf_request_handle_t *request);
int axi_dma_2d_close (cf_port_base_t *port, cf_request_handle_t *request);


int axi_dma_2d_send_ref_i (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int axi_dma_2d_send_i (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int axi_dma_2d_send_iov_i(cf_port_send_t *port,
			cf_iovec_t *iov,
			unsigned int iovcnt,
			cf_request_handle_t *request);

int axi_dma_2d_send2d_i (cf_port_send_t *port,
		void *buf,
		size_t xsize,
		size_t numlines,
		size_t xstride,
		cf_request_handle_t *request);

int axi_dma_2d_recv_i (cf_port_receive_t *port,
		void *buf,
		size_t len,
		size_t *num_recd,
		cf_request_handle_t *request);

int axi_dma_2d_recv_iov_i(cf_port_receive_t *port,
		cf_iovec_t *iov,
		unsigned int iovcnt,
		size_t *bytes_received,
		cf_request_handle_t *request);

int axi_dma_2d_recv2d_i (cf_port_receive_t *port,
		void *buf,
		size_t xsize,
		size_t numlines,
		size_t xstride,
		cf_request_handle_t *request);

int axi_dma_2d_recv_ref_i (cf_port_receive_t *port,
		void **buf,
		size_t *len,
		cf_request_handle_t *request);



#ifdef __cplusplus
};
#endif

#endif

