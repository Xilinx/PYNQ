#ifndef _XLNK_IOCTL_H
#define _XLNK_IOCTL_H

#include <linux/ioctl.h>

#define XLNK_IOC_MAGIC 'X'

#define XLNK_IOCRESET       _IO(XLNK_IOC_MAGIC, 0)

#define XLNK_IOCALLOCBUF    _IOWR(XLNK_IOC_MAGIC, 2, unsigned long)
#define XLNK_IOCFREEBUF     _IOWR(XLNK_IOC_MAGIC, 3, unsigned long)
#define XLNK_IOCADDDMABUF   _IOWR(XLNK_IOC_MAGIC, 4, unsigned long)
#define XLNK_IOCCLEARDMABUF _IOWR(XLNK_IOC_MAGIC, 5, unsigned long)

#define XLNK_IOCDMAREQUEST  _IOWR(XLNK_IOC_MAGIC, 7, unsigned long)
#define XLNK_IOCDMASUBMIT   _IOWR(XLNK_IOC_MAGIC, 8, unsigned long)
#define XLNK_IOCDMAWAIT     _IOWR(XLNK_IOC_MAGIC, 9, unsigned long)
#define XLNK_IOCDMARELEASE  _IOWR(XLNK_IOC_MAGIC, 10, unsigned long)





#define XLNK_IOCDEVREGISTER _IOWR(XLNK_IOC_MAGIC, 16, unsigned long)
#define XLNK_IOCDMAREGISTER _IOWR(XLNK_IOC_MAGIC, 17, unsigned long)
#define XLNK_IOCDEVUNREGISTER   _IOWR(XLNK_IOC_MAGIC, 18, unsigned long)
#define XLNK_IOCCDMAREQUEST _IOWR(XLNK_IOC_MAGIC, 19, unsigned long)
#define XLNK_IOCCDMASUBMIT  _IOWR(XLNK_IOC_MAGIC, 20, unsigned long)
#define XLNK_IOCMCDMAREGISTER   _IOWR(XLNK_IOC_MAGIC, 23, unsigned long)
#define XLNK_IOCCACHECTRL   _IOWR(XLNK_IOC_MAGIC, 24, unsigned long)

#define XLNK_IOCSHUTDOWN    _IOWR(XLNK_IOC_MAGIC, 100, unsigned long)
#define XLNK_IOCRECRES      _IOWR(XLNK_IOC_MAGIC, 101, unsigned long)

#define XLNK_IOC_MAXNR      101

#endif
