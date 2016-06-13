#ifndef AXI_DMA_SG_DM_H
#define AXI_DMA_SG_DM_H
#include "xlnk_core_cf.h"
#include "cf_lib.h"

#ifdef __cplusplus
extern "C" {
#endif

struct axi_dma_sg_info_struct { // info used for dma_register
	char *name; // actually the type-name; example - xilinx-axidma - used for dma_register
	int seq_num; // sequence number needed by xlnk; must be unique and "complete in 0..n"
	int base_addr;
	int addr_range;
	int num_channels; // must be 1 or 2, and if 2, the first channel must be the send channel
	int dir_chan0; // either DMA_TO_DEV or DMA_FROM_DEV if num_channels is 1, otherwise this field is DMA_TO_DEV
	int dir_chan1; // ignored if  num_channels is 1, otherwise this field is DMA_FROM_DEV
	int poll_mode_chan0; // this info is needed at registration time by the dma driver
	int poll_mode_chan1; // this info is needed at registration time by the dma driver
	int irq_send, irq_recv; // irq num must be consistent with hw connection and must be 0 if the channel is not present
};

struct axi_dma_sg_channel_info_struct { // info used for dma_open and dma_close
	// struct axi_dma_sg_info_struct *dma_info;
	char *name; 
	// example - xilinx-axidma.0chan0 ; 
	// extend the name in dma_info with the seq_num & chan0 for first channel  or chan1 for second channel
	xlnk_handle_t dmachan;
	int state ; // 0 for not-opened and 1 for opened
};

struct axi_dma_sg_transaction_info_struct { // info used for dma_submit - adds port ID & flag to the channel info
	// flag can be dynamic because the same submit function is used for kernel alloc, physical and virtual buffers
	struct axi_dma_sg_channel_info_struct *dma_channel_info;
	int port_id; // ID of stream port - 0 if the dma channel serves just 1 port, else a port ID
	// int nappwords; // used only for send must be equal to 5
	// int appwords[5] ; // example - { 0, ID, 0, 0, 0}
	int flag; // for kernel allocated, physical, coherent, poll mode etc., as defined by xlnk - must match the dma_info_struct vallues
	xlnk_handle_t dmahandle; // wait handle
};

typedef struct axi_dma_sg_info_struct axi_dma_sg_info_t;
typedef struct axi_dma_sg_channel_info_struct axi_dma_sg_channel_info_t;
typedef struct axi_dma_sg_transaction_info_struct axi_dma_sg_transaction_info_t;

void axi_dma_sg_register (void *info);
void axi_dma_sg_unregister (void *info);

int axi_dma_sg_open (cf_port_base_t *port, cf_request_handle_t *request);
int axi_dma_sg_close (cf_port_base_t *port, cf_request_handle_t *request);


int axi_dma_sg_send_i (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int axi_dma_sg_recv_i (cf_port_receive_t *port,
		void *buf,
		size_t len,
		size_t *num_recd,
		cf_request_handle_t *request);

int axi_dma_sg_recv_ref (cf_port_receive_t *port,
		void **buf,
		size_t *len,
		cf_request_handle_t *request);

#ifdef __cplusplus
};
#endif

#endif

