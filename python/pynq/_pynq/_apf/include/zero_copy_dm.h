#ifndef ZERO_COPY_DM_H
#define ZERO_COPY_DM_H

#include "cf_lib.h"

#ifdef __cplusplus
extern "C" {
#endif

struct zero_copy_info_struct {
	accel_info_t *accel_info;
	char *reg_name;
	int needs_cache_flush_invalidate;
	int dir_chan; // XLNK_{DMA_TO_DEV,DMA_FROM_DEV,BI_DIRECTIONAL}
	int status_reg_offset;
	int data_reg_offset;
	int status_reg_val; // this is the value to ensure that the data_reg is valid/ready
	int read_status_reg_offset;
	int read_status_reg_val; // this is the value to ensure that the data_reg is valid/ready
};
typedef struct zero_copy_info_struct zero_copy_info_t;

void zero_copy_register (void *info);
void zero_copy_unregister (void *info);

int zero_copy_open (cf_port_base_t *port, cf_request_handle_t *request);
int zero_copy_close (cf_port_base_t *port, cf_request_handle_t *request);


int zero_copy_send_ref_i (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int zero_copy_send_i (cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);

int zero_copy_recv (cf_port_receive_t *port,
		void *buf,
		size_t len,
		size_t *num_recd,
		cf_request_handle_t *request);

int zero_copy_recv_ref (cf_port_receive_t *port,
		void **buf,
		size_t *len,
		cf_request_handle_t *request);



#ifdef __cplusplus
};
#endif

#endif

