#ifndef D_cf_trace
#define D_cf_trace

#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef NDEBUG
#define CF_TRACE(...)
#else
extern int cf_trace_enabled;
#define CF_TRACE(...) do { if (cf_trace_enabled) cf_trace(__VA_ARGS__); } while(0)
#endif

extern void cf_trace(
	const char *fmt,
	...);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_trace */
