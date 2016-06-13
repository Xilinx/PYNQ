#ifndef AXI_LITE_DM_H
#define AXI_LITE_DM_H

#include "cf_lib.h"

#ifdef __cplusplus
extern "C" {
#endif

struct axi_lite_info_struct {
	accel_info_t *accel_info;
	char *reg_name;
	int status_reg_offset;
	int data_reg_offset;
	int status_reg_val; // this is the value to ensure that the data_reg is valid/ready
	int data_type; // 0 for writing the same offset with every member of the input buf, 1 for incrementing the base offset for each member of the input buf
	// two additional status vals to support IO registers 
	int read_status_reg_offset;
	int read_status_reg_val;
};
typedef struct axi_lite_info_struct axi_lite_info_t;

void axi_lite_register (void *info);
void axi_lite_unregister (void *info);

int axi_lite_open (cf_port_base_t *port, cf_request_handle_t *request);
int axi_lite_close (cf_port_base_t *port, cf_request_handle_t *request);


int axi_lite_send (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int axi_lite_recv (cf_port_receive_t *port,
		void *buf,
		size_t len,
		size_t *num_recd,
		cf_request_handle_t *request);

int axi_lite_recv_ref (cf_port_receive_t *port,
		void **buf,
		size_t *len,
		cf_request_handle_t *request);



#ifdef __cplusplus
};
#endif

#endif

