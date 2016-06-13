#ifndef D_cf_mem_stream
#define D_cf_mem_stream

#include "cf_sw_fifo.h"
#include "cf_util.h"
#include "cf_atomic.h"
#include "cf_pending.h"

#ifdef __cplusplus
extern "C" {
#endif


typedef struct cf_mem_stream_struct {
	cf_pending_t pending;
	cf_atomic_int_t state;
	cf_sw_fifo_t send;
	cf_sw_fifo_t receive;
} cf_mem_stream_t;


#define CF_MEM_STREAM_OBJ(NAME, TYPE, LEN)				\
	struct {							\
		cf_mem_stream_t stream;					\
		cf_request_info_t *data_send[(LEN) + 1];		\
		cf_request_info_t *data_receive[(LEN) + 1];		\
	} NAME = {							\
		{							\
			{ 0 },						\
			0,						\
			CF_SW_FIFO_INIT(NAME.stream.send, NAME.data_send), \
			CF_SW_FIFO_INIT(NAME.stream.receive, NAME.data_receive), \
		}							\
	}


#define CF_MEM_STREAM_SEND_INIT(INFO) {			\
		{					\
			(INFO),				\
			&cf_mem_stream_send_open,	\
			&cf_mem_stream_send_close	\
		},					\
		&cf_mem_stream_send_buffer,		\
		&cf_mem_stream_send_buffer,		\
		&cf_util_send_iov			\
	}


#define CF_MEM_STREAM_RECEIVE_INIT(INFO) {		\
		{					\
			(INFO),				\
			&cf_mem_stream_receive_open,	\
			&cf_mem_stream_receive_close	\
		},					\
		&cf_mem_stream_receive_reference,	\
		&cf_mem_stream_receive_buffer,		\
		&cf_util_receive_iov			\
	}


/* Open sender side */
extern int cf_mem_stream_send_open(
	cf_port_base_t *port,
	cf_request_handle_t *request);


/* Close sender side */
extern int cf_mem_stream_send_close(
	cf_port_base_t *port,
	cf_request_handle_t *request);


/* Send buffer */
extern int cf_mem_stream_send_buffer(
	cf_port_send_t *port,
	void *buf,
	size_t len,
	cf_request_handle_t *request);


/* Open receive side */
extern int cf_mem_stream_receive_open(
	cf_port_base_t *port,
	cf_request_handle_t *request);


/* Close receive side */
extern int cf_mem_stream_receive_close(
	cf_port_base_t *port,
	cf_request_handle_t *request);


/* Receive reference to buffer */
extern int cf_mem_stream_receive_reference(
	cf_port_receive_t *port,
	void **buf,
	size_t *len,
	cf_request_handle_t *request);


/* Receive buffer */
extern int cf_mem_stream_receive_buffer(
	cf_port_receive_t *port,
	void *buf,
	size_t len,
	size_t *bytes_received,
	cf_request_handle_t *request);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_mem_stream */
