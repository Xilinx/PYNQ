/*
 * @author Giuseppe Natale
 * @date   27 JAN 2016
 */


#include "xil_types.h"
#include "video_commons.h"


typedef struct{
    PyObject_HEAD
    u8 *frame_buffer[NUM_FRAMES];
    unsigned int single_frame;
} videoframeObject;

extern PyObject *get_frame(videoframeObject *self, unsigned int index);
extern PyObject *get_frame_addr(videoframeObject *self, unsigned int index);
extern PyObject *get_frame_phyaddr(videoframeObject *self, unsigned int index);
extern PyObject *set_frame(videoframeObject *self, unsigned int index, 
                           PyByteArrayObject *new_frame);

extern PyTypeObject videoframeType;
extern PyTypeObject videocaptureType;
extern PyTypeObject videodisplayType;

