#ifndef AXI_FIFO_DM_H
#define AXI_FIFO_DM_H
#ifdef __cplusplus
extern "C" {
#endif  

#include "xlnk_core_cf.h"

#define AXI_FIFO_DM_TO_DEV 0
#define AXI_FIFO_DM_FROM_DEV 1

typedef struct axi_fifo_info_struct axi_fifo_info_t;
typedef struct axi_fifo_channel_info_struct axi_fifo_channel_info_t;
typedef struct axi_fifo_transaction_info_struct axi_fifo_transaction_info_t;

struct axi_fifo_info_struct {
	char *name;
	int device_id;
	int phys_base_addr;
	int virt_base_addr; // Computed when registering device
	int addr_range;
	int num_channels;
	int dir_chan0;
	int dir_chan1;
	int poll_mode_chan0;
	int poll_mode_chan1;
	int irq_send;
  int irq_recv;
};

struct axi_fifo_channel_info_struct {
	char *name; 
	//xlnk_handle_t fifochan;
  axi_fifo_info_t *fifoinfo;
};

/* info used for fifo_submit - adds port ID & flag to the channel info flag
   can be dynamic because the same submit function is used for kernel alloc,
   physical and virtual buffers */
struct axi_fifo_transaction_info_struct {
	struct axi_fifo_channel_info_struct *fifo_channel_info;
	int port_id; // ID of stream port - 0 if the fifo channel serves just 1
               // port, else a port ID
	int flag;
	xlnk_handle_t fifohandle;
};

int axi_fifo_register (axi_fifo_info_t *axi_fifo_info);

int axi_fifo_unregister (axi_fifo_info_t *axi_fifo_info);

int axi_fifo_open (cf_port_base_t *port, cf_request_handle_t *request);
int axi_fifo_close (cf_port_base_t *port, cf_request_handle_t *request);


int axi_fifo_send (cf_port_send_t *port,
                    void *buf,
                    size_t len,
                    cf_request_handle_t *request);
  
int axi_fifo_recv (cf_port_receive_t *port,
                    void *buf,
                    size_t len,
                    size_t *num_recd,
                    cf_request_handle_t *request);
  
int axi_fifo_recv_ref (cf_port_receive_t *port,
                        void **buf,
                        size_t *len,
                        cf_request_handle_t *request);
  
#ifdef __cplusplus
}
#endif

#endif /* AXI_FIFO_DM_H */
