#ifndef D_cf_pending
#define D_cf_pending

#include "cf_lib.h"
#include "cf_atomic.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct cf_pending_struct cf_pending_t;

struct cf_pending_struct {
	cf_pending_t *next;
	cf_atomic_int_t on_pending;
	int (*run_pending)(cf_pending_t *self);
};

extern void cf_add_pending(cf_pending_t *pending);
extern void cf_run_pending(void);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_pending */
