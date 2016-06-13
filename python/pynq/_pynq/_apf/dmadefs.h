#include "sds_lib.h"
#include "axi_dma_simple_dm.h"
#include "cf_lib.h"

extern cf_request_handle_t custom_handle[50];
cf_port_send_t getport_send(axi_dma_simple_channel_info_t *custom_info);
cf_port_receive_t getport_recv(axi_dma_simple_channel_info_t *custom_info);
cf_port_base_t getport_base(axi_dma_simple_channel_info_t *custom_info);

struct cf_request_handle_struct {
	char dummy;
};
