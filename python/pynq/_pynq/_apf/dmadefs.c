#include "dmadefs.h"

cf_request_handle_t custom_handle[50];

cf_port_send_t getport_send(axi_dma_simple_channel_info_t *custom_info)
{
    cf_port_send_t x = { .base = { 
		.channel_info = custom_info, 
		.open_i = &axi_dma_simple_open, 
		.close_i = &axi_dma_simple_close },
		};
        return x;
}

cf_port_receive_t getport_recv(axi_dma_simple_channel_info_t *custom_info)
{
  cf_port_receive_t x = { .base = { 
		.channel_info = custom_info, 
		.open_i = &axi_dma_simple_open, 
		.close_i = &axi_dma_simple_close },
		.receive_ref_i = 0,
		};
        return x;
}

cf_port_base_t getport_base(axi_dma_simple_channel_info_t *custom_info)
{
  cf_port_base_t x = {
		.channel_info = custom_info, 
		.open_i = &axi_dma_simple_open, 
		.close_i = &axi_dma_simple_close };
        return x;
}
