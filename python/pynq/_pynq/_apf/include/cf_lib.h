#ifndef D_cf_lib
#define D_cf_lib

#include <stdlib.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int cf_status_t;
typedef struct cf_context_struct cf_context_t;
typedef struct cf_request_handle_struct *cf_request_handle_t;
typedef struct cf_request_info_struct cf_request_info_t;
typedef struct cf_port_base_struct cf_port_base_t;
typedef struct cf_port_receive_struct cf_port_receive_t;
typedef struct cf_port_send_struct cf_port_send_t;
typedef struct cf_port_addressable_struct cf_port_addressable_t;
typedef struct cf_alloc_attr_struct cf_alloc_attr_t;
typedef struct cf_iovec_struct cf_iovec_t;


/*
 * Error codes
 */
enum {
	CF_STATUS_OKAY,
	CF_STATUS_PENDING,
	CF_STATUS_EMPTY,
	CF_STATUS_FULL,
	CF_STATUS_INVALID,
	CF_STATUS_NOMEM,
	CF_STATUS_ALREADY_OPEN,
	CF_STATUS_NOT_OPEN,
	CF_STATUS_PORT_BUSY,
	CF_STATUS_EOS
};


/*
 * cf_addressable_map flags
 */
enum {
	CF_MAP_READ = 1,		/* Enable read access */
	CF_MAP_WRITE = 2,		/* Enable write access */
	CF_MAP_ATOMIC = 4		/* Enable atomic operations */
};


/*
 * Common port object
 */
struct cf_port_base_struct {
	void *channel_info;
	int (*open_i)(
		cf_port_base_t *port,
		cf_request_handle_t *request);
	int (*close_i)(
		cf_port_base_t *port,
		cf_request_handle_t *request);
};

/*
 * Stream receiver port
 */
struct cf_port_receive_struct {
	cf_port_base_t base;
	int (*receive_ref_i)(
		cf_port_receive_t *port,
		void **buf,
		size_t *len,
		cf_request_handle_t *request);
	int (*receive_i)(
		cf_port_receive_t *port,
		void *buf,
		size_t len,
		size_t *bytes_received,
		cf_request_handle_t *request);
	int (*receive_iov_i)(
		cf_port_receive_t *port,
		cf_iovec_t *iov,
		unsigned int iovcnt,
		size_t *bytes_received,
		cf_request_handle_t *request);
};


/*
 * Stream sender port
 */
struct cf_port_send_struct {
	cf_port_base_t base;
 	int (*send_ref_i)(
		cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);
 	int (*send_i)(
		cf_port_send_t *port,
		void *buf,
		size_t len,
		cf_request_handle_t *request);
	int (*send_iov_i)(
		cf_port_send_t *port,
		cf_iovec_t *iov,
		unsigned int iovcnt,
		cf_request_handle_t *request);
};


/*
 * Addressable master port
 */
struct cf_port_addressable_struct {
	cf_port_base_t base;
	int (*getbuf_i)(
		cf_port_addressable_t *port,
		size_t offset,
		void *buf,
		size_t len,
		cf_request_handle_t *request);
	int (*setbuf_i)(
		cf_port_addressable_t *port,
		size_t offset,
		void *buf,
		size_t len,
		cf_request_handle_t *request);
	int (*alloc_i)(
		cf_port_addressable_t *port,
		size_t size,
		size_t *offset,
		cf_request_handle_t *request);
	int (*free_i)(
		cf_port_addressable_t *port,
		size_t offset,
		cf_request_handle_t *request);
	void *(*map)(
		cf_port_addressable_t *port,
		size_t offset,
		size_t size,
		int flags);
};


/*
 * Structure used to describe scatter/gather lists and
 * multidimensional arrays for cf_send_iov and cf_receive_iov family of
 * functions.
 *
 * Example scatter/gather list:
 *   cf_iovec_t iov[3] = {
 *     { &buf1, 0, 1, sizeof buf1 },
 *     { &buf2, 0, 1, sizeof buf2 },
 *     { &buf3, 0, 1, sizeof buf3 }
 *   };
 *
 * When <buf> is null and is not the first entry in the array of
 * cf_iovec_t structures then the entry in a continuation of the
 * preceding entries that together describes all or a part of a
 * multidimensional array.  The array must be layed out as a
 * consecutive byte array.
 *
 * Example partial two dimensional array:
 *   #define real_row_size real_num_cols*real_col_size
 *   cf_iovec_t iov[2] = {
 *     { &buf, real_row_size*part_start_row, real_row_size, part_num_rows },
 *     { NULL,  real_col_size*part_start_col, 1, part_num_cols*real_col_size }
 *   };
 */
struct cf_iovec_struct {
	void *buf;
	size_t offset;
	size_t stride;
	size_t elements;
};


/*
 * Get status code.
 */
extern cf_status_t cf_get_status(void);


/*
 * Set status code.
 */
extern void cf_set_status(cf_status_t status);


/*
 * Asynchronous port open.
 *
 * May return before open is complete.  Caller must call cf_wait() on
 * <request> before using port.
 */
#define cf_open_i(PORT, REQUEST)			\
	((PORT)->base.open_i(&(PORT)->base, (REQUEST)))


/*
 * Synchronous port open.
 *
 * Returns when open is complete.
 */
#define cf_open(PORT)				\
	(cf_open_internal(&(PORT)->base))
extern int cf_open_internal(
	cf_port_base_t *port);


/*
 * Asynchronous port close.
 *
 * May return before close is complete.  Caller must call cf_wait() on
 * <request>.
 */
#define cf_close_i(PORT, REQUEST)			\
	((PORT)->base.close_i(&(PORT)->base, (REQUEST)))


/*
 * Synchronous port close.
 *
 * Returns when close is complete.
 */
#define cf_close(PORT)				\
	(cf_close_internal(&(PORT)->base))
extern int cf_close_internal(
	cf_port_base_t *port);


/*
 * Asynchronous send buffer reference to stream.
 *
 * This function transfers the ownership of the buffer to the receiver
 * from the point in time of calling cf_send_ref_i() until the point
 * in time when the corresponding wait() call returns.
 *
 * May return before send is complete.  Caller must call cf_wait() on
 * <request> before reusing the buffer.
 */
extern int cf_send_ref_i(
	cf_port_send_t *port,
	void *buf,
	size_t len,
	cf_request_handle_t *request);


/*
 * Synchronous send buffer reference to stream.
 *
 * This function transfers the ownership of the buffer to the receiver
 * for the duration of the  cf_send_ref() call.
 *
 * Returns when send is complete and buffer can be reused.
 */
extern int cf_send_ref(
	cf_port_send_t *port,
	void *buf,
	size_t len);


/*
 * Asynchronous send buffer to stream.
 *
 * May return before send is complete.  Caller must call cf_wait() on
 * <request> before reusing the buffer.
 */
extern int cf_send_i(
	cf_port_send_t *port,
	void *buf,
	size_t len,
	cf_request_handle_t *request);


/*
 * Synchronous send buffer to stream.
 *
 * Returns when send is complete and buffer can be reused.
 */
extern int cf_send(
	cf_port_send_t *port,
	void *buf,
	size_t len);


/*
 * Asynchronous send of two dimentional array to stream.  The buffer
 * must be a consecutive array of bytes, i.e. not an array of pointers
 * to rows.
 *
 * May return before send is complete.  Caller must call cf_wait() on
 * <request> before reusing the buffer.
 */
extern int cf_send_2d_i(
	cf_port_send_t *port,
	void *buf,
	size_t len,
	size_t stride,
	size_t count,
	cf_request_handle_t *request);


/*
 * Synchronous send of two dimentional array to stream.  The buffer
 * must be a consecutive array of bytes, i.e. not an array of pointers
 * to rows.
 *
 * Returns when send is complete and buffer can be reused.
 */
extern int cf_send_2d(
	cf_port_send_t *port,
	void *buf,
	size_t len,
	size_t stride,
	size_t count);


/*
 * Asynchronous scatter/gather send to stream.  See definition of
 * cf_iovec_t for details about the buffer.
 *
 * May return before send is complete.  Caller must call cf_wait() on
 * <request> before reusing the buffer.
 */
extern int cf_send_iov_i(
	cf_port_send_t *port,
	cf_iovec_t *iov,
	unsigned int iovcnt,
	cf_request_handle_t *request);


/*
 * Synchronous scatter/gather send to stream.  See definition of
 * cf_iovec_t for details about the buffer.
 *
 * Returns when send is complete and buffer can be reused.
 */
extern int cf_send_iov(
	cf_port_send_t *port,
	cf_iovec_t *iov,
	unsigned int iovcnt);


/*
 * Asynchronous receive data from stream.
 *
 * May return before data has been received.  Caller must call
 * cf_wait() on <request> before using buf or len.
 */
extern int cf_receive_i(
	cf_port_receive_t *port,
	void *buf,
	size_t len,
	size_t *bytes_received,
	cf_request_handle_t *request);


/*
 * Synchronous receive data from stream.
 *
 * Returns when data has been received and buf is populated with data.
 */
extern int cf_receive(
	cf_port_receive_t *port,
	void *buf,
	size_t len,
	size_t *bytes_received);


/*
 * Asynchronous receive reference to data from stream.
 *
 * May return before data has been received.  Caller must call
 * cf_wait() on <request> before using buf or len.
 *
 * Once reference to data has been received the caller must call
 * cf_release_ref() to indicate that the referenced buffer is no
 * longer used.
 */
extern int cf_receive_ref_i(
	cf_port_receive_t *port,
	void **buf,
	size_t *len,
	cf_request_handle_t *request);


/*
 * Synchronous receive reference to data from stream.
 *
 * Returns when data has been received and *buf and *len are set.
 *
 * Once reference to data has been received the caller must call
 * cf_release_ref() to indicate that the referenced buffer is no
 * longer used.
 */
extern int cf_receive_ref(
	cf_port_receive_t *port,
	void **buf,
	size_t *len,
	cf_request_handle_t *request);


/*
 * Asynchronous receive of two dimentional array from stream.  The
 * buffer must be a consecutive array of bytes, i.e. not an array of
 * pointers to rows.
 *
 * May return before data has been received.  Caller must call
 * cf_wait() on <request> before using buf or len.
 */
extern int cf_receive_2d_i(
	cf_port_receive_t *port,
	void *buf,
	size_t len,
	size_t stride,
	size_t count,
	size_t *bytes_received,
	cf_request_handle_t *request);


/*
 * Synchronous receive of two dimentional array from stream.  The
 * buffer must be a consecutive array of bytes, i.e. not an array of
 * pointers to rows.
 *
 * Returns when data has been received and buf is populated with data.
 */
extern int cf_receive_2d(
	cf_port_receive_t *port,
	void *buf,
	size_t len,
	size_t stride,
	size_t count,
	size_t *bytes_received);


/*
 * Asynchronous scatter/gather receive from stream.  See definition of
 * cf_iovec_t for details about the buffer.
 *
 * May return before data has been received.  Caller must call
 * cf_wait() on <request> before using buf or len.
 */
extern int cf_receive_iov_i(
	cf_port_receive_t *port,
	cf_iovec_t *iov,
	unsigned int iovcnt,
	size_t *bytes_received,
	cf_request_handle_t *request);


/*
 * Synchronous receive of two dimentional array from stream.  See
 * definition of cf_iovec_t for details about the buffer.
 *
 * Returns when data has been received and buf is populated with data.
 */
extern int cf_receive_iov(
	cf_port_receive_t *port,
	cf_iovec_t *iov,
	unsigned int iovcnt,
	size_t *bytes_received);


/*
 * Asynchronous allocate memory from addressable port.
 *
 * Allocates <size> number of bytes from addressable memory space
 * associated with <port> or returns error.  Offset to allocated space
 * is stored in *offset at the completion of a successful allocation.
 *
 * May return before allocaiton is complete.  Caller must call
 * cf_wait() on <request> before using content of *offset.
 */
extern int cf_addressable_alloc_i(
	cf_port_addressable_t *port,
	size_t size,
	size_t *offset,
	cf_request_handle_t *request);


/*
 * Synchronous allocate memory from addressable port.
 *
 * Allocates <size> number of bytes from addressable memory space
 * associated with <port> or returns error.  Offset to allocated space
 * is stored in *offset at the completion of a successful allocation.
 *
 * Returns on error or when allocation is complete and *offset is
 * populated with the offset to the start of the allocated memory.
 */
extern int cf_addressable_alloc(
	cf_port_addressable_t *port,
	size_t size,
	size_t *offset);


/*
 * Asynchronous free memory allocated from addressable port.
 *
 * Free memory block starting at <offset> from addressable memory
 * space associated with <port> or returns error.  The memory block
 * starting at <offset> must have been allocated using
 * cf_addressable_alloc() or related functions.
 *
 * May return before free is complete.  Caller must call
 * cf_wait() on <request> to make sure free is complete.
 */
extern int cf_addressable_free_i(
	cf_port_addressable_t *port,
	size_t offset,
	cf_request_handle_t *request);


/*
 * Synchronous free memory from addressable port.
 *
 * Free memory block starting at <offset> from addressable memory
 * space associated with <port> or returns error.  The memory block
 * starting at <offset> must have been allocated using
 * cf_addressable_alloc() or related functions.
 *
 * Returns on error or when free is complete.
 */
extern int cf_addressable_free(
	cf_port_addressable_t *port,
	size_t offset);


/*
 * Asynchronous get from addressable port.
 *
 * Initiates copy of <size> number of bytes from <port> at <offset>
 * into <buf> or returns error.
 *
 * May return before copy is complete.  Caller must call cf_wait() on
 * <request> before using content of buf.
 */
extern int cf_getbuf_i(
	cf_port_addressable_t *port,
	size_t offset,
	void *buf,
	size_t len,
	cf_request_handle_t *request);


/*
 * Synchronous get from addressable port.
 *
 * Returns on error or when <size> number of bytes from <port> at
 * <offset> has been copied into <buf>.
 */
extern int cf_getbuf(
	cf_port_addressable_t *port,
	size_t offset,
	void *buf,
	size_t len);


/*
 * Asynchronous set to addressable port.
 *
 * Initiates copy of <size> number of bytes from <buf> to <port> at
 * <offset> or returns error.
 *
 * May return before copy is complete.  Caller must call cf_wait() on
 * <request> before modifying content of buf.
 */
extern int cf_setbuf_i(
	cf_port_addressable_t *port,
	size_t offset,
	void *buf,
	size_t len,
	cf_request_handle_t *request);


/*
 * Synchronous set to addressable port.
 *
 * Returns on error or when <size> number of bytes from <buf> has been
 * copied to <port> at <offset>.
 */
extern int cf_setbuf(
	cf_port_addressable_t *port,
	size_t offset,
	void *buf,
	size_t len);

/*
 * Synchronous map memory from addressable port into local address space.
 *
 * Maps memory <size> number of bytes starting at <offset> in
 * addressable memory space associated with <port> into local memory.
 * <flags> is set to one or more of CF_MAP_* to control how memory is
 * mapped.
 *
 * Returns the local address to the mapped memory, or ((void)-1) to
 * indicate error.
 */
extern void *cf_addressable_map(
	cf_port_addressable_t *port,
	size_t offset,
	size_t size,
	int flags);


/*
 * Unmap memory mapped using cf_addressable_map()
 */
int cf_addressable_unmap(
	void *ptr,
	size_t size);


/*
 * Release reference to buffer assoctated with request.
 *
 * This will either complete the send request or release the buffer
 * back to the system.
 */
extern void cf_release_ref(
	cf_request_handle_t *request);

/*
 * Test if request has completed
 *
 * Returns true if request completed, otherwise returns false.
 *
 * Same semantic as cf_wait() expect that it does not block.
 */
extern int cf_test(
	cf_request_handle_t *request);

/*
 * Wait for request to complete
 */
extern int cf_wait(
	cf_request_handle_t request);

/*
 * Wait for any request in list to complete
 *
 * Returns the index in list for the request that completed.
 */
extern unsigned int cf_wait_any(
	cf_request_handle_t *request_list,
	unsigned int request_count);

/*
 * Wait for all requests in list to complete
 *
 * Returns the number of requests that completed without error.
 */
extern unsigned int cf_wait_all(
	cf_request_handle_t *request_list,
	unsigned int request_count);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_lib */
