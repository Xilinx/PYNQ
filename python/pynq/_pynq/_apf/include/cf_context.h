#ifndef D_cf_context
#define D_cf_context

#include "cf_lib.h"
#include "cf_atomic.h"

#ifdef __cplusplus
extern "C" {
#endif

struct cf_context_struct {
	/* Status code of last request */
	cf_status_t status;

	/* Context ID of this context. */
	int context_id;

	/* List if unused request nodes */
	cf_request_info_t *request_free_list;
};

extern cf_context_t *cf_get_current_context(void);
extern int cf_is_valid_context(int);
extern void cf_context_expect_notification(cf_context_t *context, int on);
extern void cf_context_wait_for_notification(cf_context_t *context);
extern void cf_context_notify(int context_id);
extern void cf_context_init(void);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_context */
