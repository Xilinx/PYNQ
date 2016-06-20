#ifndef _SDS_PORTINFO_H
#define _SDS_PORTINFO_H
#include "sds_lib.h" 
/* File: /home/hackwad/workspace/filer_ex/SDDebug/_sds/p0/.cf_work/portinfo.h */
#ifdef __cplusplus
extern "C" {
#endif

cf_request_handle_t custom_request[50];
int custom_address_list[50];
int custom_address_num = 0;

void _p0_cf_framework_open(int);
void _p0_cf_framework_close(int);
extern void *sds_alloc( size_t size);
extern void sds_free(void *memptr);
#ifdef __cplusplus
};
#endif
#ifdef __cplusplus
extern "C" {
#endif
void switch_to_next_partition(int);
void init_first_partition();
void close_last_partition();
#ifdef __cplusplus
};
#endif /* extern "C" */
#endif /* _SDS_PORTINFO_H_ */
