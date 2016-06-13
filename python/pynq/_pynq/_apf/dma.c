#include "dma.h"


extern "C" void custom_dma_register(int id)
{
	axi_dma_simple_register(&custom_handle[id]);
}

extern "C" void custom_dma_unregister(int id)
{
	axi_dma_simple_unregister(&custom_handle[id]);
}

extern "C" int custom_dma_open(axi_dma_simple_channel_info_t * dstruct, int id)
{
   return 1;
   cf_port_base_t port = getport_base(dstruct); 
	return axi_dma_simple_open(
    &(port),
    &custom_handle[id]);
}

extern "C" int custom_dma_close(axi_dma_simple_channel_info_t * dstruct, int id)
{
   cf_port_base_t port = getport_base(dstruct); 
	return axi_dma_simple_close(
    &port,
    &custom_handle[id]);
}


extern "C" int custom_dma_send_i(axi_dma_simple_channel_info_t * dstruct, void *buf, size_t len,int id)
{
   cf_port_send_t port = getport_send(dstruct); 
	return axi_dma_simple_send_i(
    	&port,
	buf,len,&custom_handle[id]);
}

extern "C" int custom_dma_recv_i(axi_dma_simple_channel_info_t * dstruct, void *buf, size_t len,size_t *num_recd,int id)
{
   cf_port_receive_t port = getport_recv(dstruct); 
	return axi_dma_simple_recv_i(
   	&port,
	buf,len,num_recd,&custom_handle[id]);
}

extern "C" void custom_dma_wait(int id)
{
	axi_dma_simple_wait(&custom_handle[id]);
}
