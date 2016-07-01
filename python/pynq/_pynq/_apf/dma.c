/******************************************************************************
*
* Copyright (C) 2002 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

#include "cf_lib.h"
#include "cf_request.h"
#include "dma.h"
#include "stdio.h"
#include "xlnk_core_cf.h"
#include "axi_dma_simple_dm.h"

void init_first_partition() __attribute__ ((constructor));
void close_last_partition() __attribute__ ((destructor));
void init_first_partition()
{
  cf_context_init();
  xlnkCounterMap();
  cf_register(1);
  cf_get_current_context();
}


void close_last_partition()
{
  cf_unregister(1);
}

void cf_register(int first)
{
  int xlnk_init_done = cf_xlnk_open(first);
  if (xlnk_init_done == 0) {
//    printf("Registering device..\n");
    cf_xlnk_init(first);
  }
  else if (xlnk_init_done <0) {
    fprintf(stderr, "ERROR: unable to open xlnk %d\n", xlnk_init_done);
  }
  else {
  }
}

void cf_unregister(int last)
{
  xlnkClose(last,NULL);
}

int check_address(int * address)
{
	for (int i=0; i <= custom_address_num; i++)
	{
		if ( *address == custom_address_list[i] )
		return 1;
	}
	custom_address_num += 1;
	custom_address_list[custom_address_num] = *address;
	return 0;
}

void _internal_template(){
int * ha = (int *) sds_alloc(1);
sds_free(ha);
}


cf_port_send_t getport_send(axi_dma_simple_channel_info_t *custom_info)
{
    cf_port_send_t x = { .base = {
                .channel_info = custom_info,
                .open_i = &axi_dma_simple_open,
                .close_i = &axi_dma_simple_close },
		.send_i = axi_dma_simple_send_i,
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
		.receive_i = &axi_dma_simple_recv_i,
                };
        return x;
}

cf_port_base_t getport_base(axi_dma_simple_channel_info_t * custom_info)
{
  cf_port_base_t x = {
                .channel_info = custom_info,
                .open_i = &axi_dma_simple_open,
                .close_i = &axi_dma_simple_close };
        return x;
}

void unreg_and_close(axi_dma_simple_channel_info_t * dmainfo);
void unreg_and_close(axi_dma_simple_channel_info_t * dmainfo)
{
  cf_port_base_t port = getport_base(dmainfo);
  axi_dma_simple_unregister(dmainfo->dma_info); 
  axi_dma_simple_close(&port,NULL);
}

void reg_and_open(axi_dma_simple_channel_info_t  * dmainfo);
void reg_and_open(axi_dma_simple_channel_info_t *  dmainfo)
{
  if(check_address(&(dmainfo->dma_info->phys_base_addr)))
  {
//	printf("restarting dma instance..\n");
	unreg_and_close(dmainfo); 
  }
  cf_port_base_t port = getport_base(dmainfo);
  axi_dma_simple_register(dmainfo->dma_info);
 //  printf("opening port..%x\n",dmainfo->dma_info->phys_base_addr);
  port.open_i(&port, NULL);
}


void  _dma_send(axi_dma_simple_channel_info_t * dmainfo, void * data,int len, int handle_id);
void  _dma_send(axi_dma_simple_channel_info_t * dmainfo, void * data,int len, int handle_id)
{
    cf_port_send_t port = getport_send(dmainfo);
    int i = handle_id;
    cf_send_i(&port, data,len, &custom_request[i]);
    printf("%p\n", &custom_request[i]);
}

int _dma_wait(int handle_id, int timeout_sec);
int _dma_wait(int handle_id, int timeout_sec)
{
    axi_dma_simple_request_t * axi_dma_simple_request = (axi_dma_simple_request_t * ) custom_request[handle_id];
    axi_dma_simple_request->timeout_sec = timeout_sec;
    return cf_wait(custom_request[handle_id]);
}

void _dma_recv(axi_dma_simple_channel_info_t * dmainfo, void * data,int len, int handle_id);
void _dma_recv(axi_dma_simple_channel_info_t * dmainfo, void * data,int len, int handle_id)
{
  cf_port_receive_t port = getport_recv(dmainfo);
  int num_ret=0;
  cf_receive_i(&(port), data, len, &num_ret, &custom_request[handle_id]); 
}
