#ifndef D_cf_request
#define D_cf_request

#include "cf_context.h"

#ifdef __cplusplus
extern "C" {
#endif

#define CF_REQUEST_INFO_SIZE (sizeof(cf_request_info_t) + 8 * sizeof(void *))

typedef struct cf_request_handlers_struct cf_request_handlers_t;
typedef struct cf_request_on_free_handler_struct cf_request_on_free_handler_t;

typedef enum {
	CF_REQ_STATE_WAITING,
	CF_REQ_STATE_ACTIVE,
	CF_REQ_STATE_DONE
} cf_request_state_t;

struct cf_request_handlers_struct {
	int (*test_req)(cf_request_info_t *);
	void (*release_ref)(cf_request_info_t *);
};

struct cf_request_on_free_handler_struct {
	cf_request_on_free_handler_t *next;
	void (*handler)(void *client_data);
	void *client_data;
};

struct cf_request_info_struct {
	cf_status_t status;
	cf_atomic_int_t state;
	cf_context_t *context;
	cf_request_handlers_t *handlers;
	cf_request_on_free_handler_t *on_free_handlers;
};

extern cf_request_info_t *cf_request_alloc(
	size_t size,
	cf_request_handlers_t *handlers);

extern void cf_request_add_on_free_handler(
	cf_request_info_t *request,
	void (*handler)(void *client_data),
	void *client_data);

extern void cf_request_free(
	cf_request_info_t *request);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_request */
