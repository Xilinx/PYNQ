//
// This header file declares the Xlnk performance benchmark APIs
//

#ifndef XLNK_PERF_H
#define XLNK_PERF_H
#ifdef __cplusplus
extern "C" {
#endif

void xlnkCounterMap(void);
unsigned long xlnkGetGlobalCounter(void);
unsigned long long xlnkGetGlobalCounter64(void);
void xlnkSetGlobalCounter(unsigned long long val);

#ifdef __cplusplus
};
#endif
#endif

