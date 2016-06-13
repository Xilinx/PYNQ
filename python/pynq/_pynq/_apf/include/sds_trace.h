/*
 * sdsoc_trace.h
 *
 *  Created on: Sep 2, 2015
 *      Author: sskalick
 */

#ifndef SDSOC_TRACE_H_
#define SDSOC_TRACE_H_

typedef struct trace_entry_struct {
  long long unsigned timestamp;
  unsigned type;
  unsigned ID;
} sds_trace_entry;

typedef struct trace_list_struct {
  sds_trace_entry *entries;
  size_t used;
  size_t size;
  struct trace_list_struct *next;
} sds_trace_list;

void trace_list_add(long long unsigned timestamp, unsigned type, unsigned ID);
void sds_trace_setup(void);
void sds_trace_cleanup(void);
void _sds_print_trace_entry(sds_trace_entry *entry);
void _sds_print_trace(void);
void _sds_trace_log_HW(unsigned ID, unsigned type);
void _sds_trace_log_SW(unsigned ID, unsigned type);
void sds_trace(unsigned ID, unsigned type);
void sds_trace_stop();

#endif /* SDSOC_TRACE_H_ */
