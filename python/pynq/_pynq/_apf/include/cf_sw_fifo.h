#ifndef D_cf_sw_fifo
#define D_cf_sw_fifo

#include "cf_lib.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct cf_sw_fifo_struct {
	unsigned int read_offset;
	unsigned int write_offset;
	unsigned int start_offset;
	unsigned int end_offset;
	unsigned int item_size;
} cf_sw_fifo_t;

#define CF_SW_FIFO_INIT(OBJ, DATA) {					\
		(char *)(DATA) - (char *)&(OBJ),			\
		(char *)(DATA) - (char *)&(OBJ),			\
		(char *)(DATA) - (char *)&(OBJ),			\
		(char *)(DATA) + (sizeof (DATA)) - (char *)&(OBJ),	\
		sizeof *(DATA)						\
	}

#define CF_SW_FIFO_INIT2(OBJ, DATA, SIZE) do {				\
		(OBJ).read_offset = (char *)(DATA) - (char *)&(OBJ);	\
		(OBJ).write_offset = (char *)(DATA) - (char *)&(OBJ);	\
		(OBJ).start_offset = (char *)(DATA) - (char *)&(OBJ);	\
		(OBJ).end_offset = (char *)(DATA) + (SIZE) - (char *)&(OBJ); \
		(OBJ).item_size = sizeof *(DATA);			\
	} while(0)

#define CF_SW_FIFO_OBJ(NAME, TYPE, LEN)				\
	struct {						\
		cf_sw_fifo_t fifo;				\
		TYPE data[(LEN) + 1];				\
	} NAME


extern size_t cf_sw_fifo_get_available(
	cf_sw_fifo_t *fifo,
	void **start);

extern void cf_sw_fifo_set_available(
	cf_sw_fifo_t *fifo,
	void *end);

extern void cf_sw_fifo_reserve(
	cf_sw_fifo_t *fifo,
	void **start,
	void **end);

extern void cf_sw_fifo_commit(
	cf_sw_fifo_t *fifo,
	void *end);

#ifdef __cplusplus
}
#endif

#endif /* D_cf_sw_fifo */
