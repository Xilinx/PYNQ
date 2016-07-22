/*
 * CPython bindings for a video frame object - to be used in conjuction with
 * _video._capture and _video._display
 *
 * @author Giuseppe Natale
 * @date   27 JAN 2016
 */


#include <Python.h>
#include <structmember.h>
#include <stdio.h>
#include <string.h>
#include "xil_types.h"
#include "utils.h"
#include "video_commons.h"
#include "_video.h"


/*****************************************************************************/
/* Defining the dunder methods                                               */

/*
 * deallocator
 */
static void videoframe_dealloc(videoframeObject* self){
    for(int i = 0; i < NUM_FRAMES; i++)
        frame_free(self->frame_buffer[i]);
    Py_TYPE(self)->tp_free((PyObject*)self);
}

/*
 * __new()__ method
 */
static PyObject *videoframe_new(PyTypeObject *type, PyObject *args, 
                                  PyObject *kwds){
    videoframeObject *self;
    self = (videoframeObject *)type->tp_alloc(type, 0);
    return (PyObject *)self;
}

/*
 * __init()__ method
 *
 * Python Constructor: frame([single_frame])
 * set single_frame to 1 if you want this object to hold a single frame 
 * (that will be available at index 0)
 */
static int videoframe_init(videoframeObject *self, PyObject *args){
    self->single_frame = 0;
    if (!PyArg_ParseTuple(args, "|I", &self->single_frame))
        return -1;
    if (self->single_frame == 1) // allocate just the frame at position 0
    {
        if((self->frame_buffer[0] = (u8 *)frame_alloc(sizeof(u8)*MAX_FRAME))
           == NULL){
            PyErr_Format(PyExc_MemoryError,"Unable to allocate memory");
            return -1; 
        }
        return 0;
    }
    self->single_frame = 0; // reset to 0 in case user specified a non valid value
    for(int i = 0; i < NUM_FRAMES; i++)
        if((self->frame_buffer[i] = (u8 *)frame_alloc(sizeof(u8)*MAX_FRAME))
           == NULL){
            PyErr_Format(PyExc_MemoryError,"Unable to allocate memory");
            return -1; 
        }
    return 0;
}

/*
 * exposing members
 */
static PyMemberDef videoframe_members[] = {
    {"single_frame", T_UINT, offsetof(videoframeObject, single_frame),READONLY,
     "1 if this object holds a single frame"},
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* functions used to set or get a frame - used by the frame member           */
/* functions and by _capture.c and _display.c                                */

/*
 * get a bytearray object holding the frame at index
 */
PyObject *get_frame(videoframeObject *self, unsigned int index){
    if(index < 0 || index >= NUM_FRAMES){
        PyErr_Format(PyExc_ValueError, 
                     "Index %d out of range [%d,%d]",
                     index, 0, NUM_FRAMES-1);
        return NULL;
    }
  return PyMemoryView_FromMemory((char *)self->frame_buffer[index],
                                         MAX_FRAME,PyBUF_READ);
}

/*
 * set the frame at index from the bytearray new_frame
 */
PyObject *set_frame(videoframeObject *self, unsigned int index, 
                    PyByteArrayObject *new_frame){
    if(PyByteArray_Size((PyObject *)new_frame) != MAX_FRAME){
        PyErr_Format(PyExc_ValueError, 
                     "new_frame bytearray must have %d number of elements",
                     MAX_FRAME);
        return NULL;        
    }
    memcpy(self->frame_buffer[index], new_frame->ob_start, MAX_FRAME);
    Py_RETURN_NONE;
}

/*****************************************************************************/
/* Actual C bindings - member functions                                      */

PyObject *videoframe_call(videoframeObject *self, PyObject *args, 
                                 PyObject *kw){
    unsigned int index;
    PyObject *new_frame = NULL;
    if (!PyArg_ParseTuple(args, "I|O", &index, &new_frame))
        return NULL;
    if(self->single_frame == 1) // ignore index parameter
        index = 0;              // as there is only one frame
    if(new_frame != NULL){ // set mode
        if (!PyByteArray_CheckExact(new_frame)){
            PyErr_SetString(PyExc_SyntaxError, 
                            "new_frame argument must be a bytearray");
            return NULL;
        }
        return set_frame(self, index, (PyByteArrayObject *)new_frame);
    }
    else // get mode
        return get_frame(self, index);
}

static PyObject *videoframe_max_frames(videoframeObject *self){
    if(self->single_frame == 1)
        return Py_BuildValue("i", 1);
    return Py_BuildValue("i", NUM_FRAMES);
}

static PyObject *videoframe_max_width(videoframeObject *self){
    return Py_BuildValue("i", MAX_FRAME_WIDTH);
}

static PyObject *videoframe_max_height(videoframeObject *self){
    return Py_BuildValue("i", MAX_FRAME_HEIGHT);
}

/*****************************************************************************/
/* Defining the methods struct                                               */

static PyMethodDef videoframe_methods[] = {
    {"max_frames", (PyCFunction)videoframe_max_frames, METH_VARARGS,
     "Get the maximum number of frame stored by this frame buffer."
    },
    {"max_width", (PyCFunction)videoframe_max_width, METH_VARARGS,
     "Get the maximum supported width for a frame."
    },
    {"max_height", (PyCFunction)videoframe_max_height, METH_VARARGS,
     "Get the maximum supported height for a frame."
    },
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* Defining the type object                                                  */

PyTypeObject videoframeType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    "_video._frame",                            /* tp_name */
    sizeof(videoframeObject),                   /* tp_basicsize */
    0,                                          /* tp_itemsize */
    (destructor)videoframe_dealloc,             /* tp_dealloc */
    0,                                          /* tp_print */
    0,                                          /* tp_getattr */
    0,                                          /* tp_setattr */
    0,                                          /* tp_reserved */
    0,                                          /* tp_repr */
    0,                                          /* tp_as_number */
    0,                                          /* tp_as_sequence */
    0,                                          /* tp_as_mapping */
    0,                                          /* tp_hash  */
    (ternaryfunc)videoframe_call,               /* tp_call */
    0,                                          /* tp_str */
    0,                                          /* tp_getattro */
    0,                                          /* tp_setattro */
    0,                                          /* tp_as_buffer */
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,   /* tp_flags */
    "Video Frame object",                       /* tp_doc */
    0,                                          /* tp_traverse */
    0,                                          /* tp_clear */
    0,                                          /* tp_richcompare */
    0,                                          /* tp_weaklistoffset */
    0,                                          /* tp_iter */
    0,                                          /* tp_iternext */
    videoframe_methods,                         /* tp_methods */
    videoframe_members,                         /* tp_members */
    0,                                          /* tp_getset */
    0,                                          /* tp_base */
    0,                                          /* tp_dict */
    0,                                          /* tp_descr_get */
    0,                                          /* tp_descr_set */
    0,                                          /* tp_dictoffset */
    (initproc)videoframe_init,                  /* tp_init */
    0,                                          /* tp_alloc */
    videoframe_new,                             /* tp_new */
};
