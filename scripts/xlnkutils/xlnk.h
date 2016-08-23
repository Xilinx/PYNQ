#include <linux/ioctl.h>

#define XLNK_IOC_MAGIC 'X'

#define XLNK_IOCRESET       _IO(XLNK_IOC_MAGIC, 0)

#define XLNK_IOCALLOCBUF    _IOWR(XLNK_IOC_MAGIC, 2, unsigned long)
#define XLNK_IOCFREEBUF     _IOWR(XLNK_IOC_MAGIC, 3, unsigned long)
#define XLNK_IOCCACHECTRL   _IOWR(XLNK_IOC_MAGIC, 24, unsigned long)

#define XLNK_IOCSHUTDOWN    _IOWR(XLNK_IOC_MAGIC, 100, unsigned long)
#define XLNK_IOCRECRES      _IOWR(XLNK_IOC_MAGIC, 101, unsigned long)

#define XLNK_IOC_MAXNR      101

typedef union {
    struct {
        unsigned int len;
        unsigned int *idptr;
        unsigned int *phyaddrptr;
        unsigned int cacheable;
    } allocbuf;
    struct {
        unsigned int id;
        void *buf;
    } freebuf;
#define XLNK_MAX_APPWORDS 5
    struct {
        void *phys_addr;
        int size;
        int action;
    } cachecontrol;
} xlnk_args;