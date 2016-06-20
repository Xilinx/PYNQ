#include "sds_lib.h" 


extern void *sds_alloc( size_t size);
extern void sds_free(void *memptr);

cf_request_handle_t custom_request[50];
int custom_address_list[50];
int custom_address_num = 0;

void cf_register(int);
void cf_unregister(int);

void _p0_cf_framework_open(int);
void _p0_cf_framework_close(int);

void switch_to_next_partition(int);
void init_first_partition();
void close_last_partition();
