#ifndef D_cf_util
#define D_cf_util

#include "cf_lib.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Utility function for data movers that do not have native support
 * for receive with iovec.
 */
int cf_util_receive_iov(
	cf_port_receive_t *port,
	cf_iovec_t *iov,
	unsigned int iovcnt,
	size_t *bytes_received,
	cf_request_handle_t *request);

/*
 * Utility function for data movers that do not have native support
 * for send with iovec.
 */
int cf_util_send_iov(
	cf_port_send_t *port,
	cf_iovec_t *iov,
	unsigned int iovcnt,
	cf_request_handle_t *request);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_util */
