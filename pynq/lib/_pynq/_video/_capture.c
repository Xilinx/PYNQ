/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  All rights reserved.
 * 
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice, 
 *     this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright 
 *      notice, this list of conditions and the following disclaimer in the 
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its 
 *      contributors may be used to endorse or promote products derived from 
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file _capture.c
 *
 * CPython bindings for a video capture peripheral (video_capture.h)
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a gn  01/27/16 release
 * 1.00b bj  09/01/16 add license header
 *
 * </pre>
 *
 *****************************************************************************/

#include <Python.h>
#include <structmember.h>  
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include "video_commons.h"
#include "video_capture.h"
#include "_video.h"

typedef struct{
    PyObject_HEAD
    VideoCapture *capture;
    videoframeObject *frame;
} videocaptureObject;


/*****************************************************************************/
/* Defining the dunder methods                                               */

/*
 * deallocator
 */
static void videocapture_dealloc(videocaptureObject* self){
    VideoStop(self->capture);

    Py_Del_XAxiVdma(self->capture->vdma);
    Py_Del_XVtc(&(self->capture->vtc));
    Py_Del_XGpio(self->capture->gpio);
    free(self->capture);
    Py_TYPE(self)->tp_free((PyObject*)self);

    for(int i = 0; i < NUM_FRAMES; i++)
        cma_free(self->frame->frame_buffer[i]);

    char sysbuf[128];
	sprintf(sysbuf, "echo '_capture del' >> /tmp/video.log");
	system(sysbuf);
}

/*
 * __new()__ method
 */
static PyObject *videocapture_new(PyTypeObject *type, PyObject *args, 
                                  PyObject *kwds){
    char sysbuf[128];
	sprintf(sysbuf, "echo '_capture new' >> /tmp/video.log");
	system(sysbuf);

    videocaptureObject *self;
    self = (videocaptureObject *)type->tp_alloc(type, 0);
    if((self->capture = (VideoCapture *)malloc(sizeof(VideoCapture))) == NULL){
        PyErr_Format(PyExc_MemoryError, "Unable to allocate memory");
        return NULL;        
    }
    return (PyObject *)self;
}

/*
 * __init()__ method
 *
 * Python Constructor:  capture(vdma_dict,gpio_dict,vtcBaseAddress,
 *                              [video.frame])
 */
static int videocapture_init(videocaptureObject *self, PyObject *args){
    self->frame = NULL;
    int init_timeout;
    PyObject *vdma_dict = NULL, *gpio_dict = NULL;
    unsigned int vtcBaseAddress;
    if (!PyArg_ParseTuple(args, "OOIi|O", &vdma_dict, &gpio_dict,  
                          &vtcBaseAddress, &init_timeout, &self->frame))
        return -1;
    if (!(PyDict_Check(vdma_dict) && PyDict_Check(gpio_dict)))
        return -1;

    if(self->frame == NULL){ 
        self->frame = PyObject_New(videoframeObject, &videoframeType);
        for(int i = 0; i < NUM_FRAMES; i++)
            if((self->frame->frame_buffer[i] = 
                (u8 *)cma_alloc(sizeof(u8)*MAX_FRAME, 0)) == NULL){
                PyErr_Format(PyExc_MemoryError, "Unable to allocate \
                    frame buffer memory");
                return -1;            
            }
    }

    int status = VideoInitialize(self->capture, vdma_dict, gpio_dict, 
                                 vtcBaseAddress, self->frame->frame_buffer, 
                                 STRIDE, init_timeout);
    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_LookupError, 
                     "_video._capture initialization failed [%d]", status);
        return -1;
    }
    return 0;

}


/*
 * __str()__ method
 */
static PyObject *videocapture_str(videocaptureObject *self){
    VtcDetect(self->capture);
    char str[200];
    sprintf(str, "Video Capture \r\n   State: %d \r\n   \
                  Current Index: %d \r\n   Current Width: %d \r\n   \
                  Current Height: %d", 
            self->capture->state, self->capture->curFrame, 
            self->capture->timing.HActiveVideo, 
            self->capture->timing.HActiveVideo);
    return Py_BuildValue("s",str);
}

/*
 * exposing members
 */
static PyMemberDef videocapture_members[] = {
    {"framebuffer", T_OBJECT, offsetof(videocaptureObject, frame), READONLY,
     "FrameBuffer object"},
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* Actual C bindings - member functions                                      */

/*
 * frame_index([new_index])
 * get current index or if the argument is specified set it to a new one
 * within the allowed range
 */
static PyObject *videocapture_frame_index(videocaptureObject *self, 
                                          PyObject *args){
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs > 0){
        unsigned int newIndex = 0;
        if (!PyArg_ParseTuple(args, "I", &newIndex))
            return NULL;
        if(newIndex >= 0 && newIndex < NUM_FRAMES){       
            self->capture->curFrame = newIndex;
            int status = VideoChangeFrame(self->capture, newIndex);
            if (status != XST_SUCCESS){
                PyErr_Format(PyExc_SystemError, 
                             "Unable to change frame [%d]", status);
                return NULL;
            }
            Py_RETURN_NONE;
        }
        else{
            PyErr_Format(PyExc_ValueError, 
                         "Index %d out of range [%d,%d]",
                         newIndex, 0, NUM_FRAMES-1);
            return NULL;
        }
    }
    return Py_BuildValue("I", self->capture->curFrame);
}


/*
 * frame_index_next()
 * Set the frame index to the next one and return it
 */
static PyObject *videocapture_frame_index_next(videocaptureObject *self){
    unsigned int newIndex = self->capture->curFrame + 1;
     if(newIndex >= NUM_FRAMES)
        newIndex = 0;         
    int status = VideoChangeFrame(self->capture, newIndex);   
    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_SystemError, 
                     "Unable to change frame [%d]", status);
        return NULL;
    }
    return Py_BuildValue("I", self->capture->curFrame);
}

/*
 * frame_width()
 * get current width
 */
static PyObject *videocapture_frame_width(videocaptureObject *self){
    VtcDetect(self->capture);
    return Py_BuildValue("I", self->capture->timing.HActiveVideo);
}

/*
 * frame_height()
 * get current height
 */
static PyObject *videocapture_frame_height(videocaptureObject *self){
    VtcDetect(self->capture);
    return Py_BuildValue("I", self->capture->timing.VActiveVideo);
}

/*
 * start()
 */
static PyObject *videocapture_start(videocaptureObject *self){
    int status = VideoStart(self->capture);
    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_SystemError, 
                     "Unable to start capture device [%d]", status);
        return NULL;
    }
    Py_RETURN_NONE;
}

/*
 * stop()
 */
static PyObject *videocapture_stop(videocaptureObject *self){
    int status = VideoStop(self->capture);
    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_SystemError, 
                     "Unable to stop capture device [%d]", status);
        return NULL;
    }
    Py_RETURN_NONE;
}

/*
 * state()
 */
static PyObject *videocapture_state(videocaptureObject *self){
    return Py_BuildValue("I", self->capture->state);
}


/*
 * frame([index])
 * 
 * just a wrapper of get_frame() and set_frame() defined for the videoframe
 * object. supports only read_mode.
 */
static PyObject *videocapture_frame(videocaptureObject *self, PyObject *args){
    unsigned int index = self->capture->curFrame;
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs == 0 || (nargs == 1 && PyArg_ParseTuple(args, "I", &index))){
        return get_frame(self->frame, index);
    }
    else{
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Invalid argument");
        return NULL;        
    }
}

/*
 * frame_addr([index])
 * 
 * just a wrapper of get_frame_addr().
 */
static PyObject *videocapture_frame_addr(videocaptureObject *self, 
                                         PyObject *args){
    unsigned int index = self->capture->curFrame;
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs == 0 || (nargs == 1 && PyArg_ParseTuple(args, "I", &index))){
        return get_frame_addr(self->frame, index);
    }
    else {
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Invalid arguemnts or invalid \
                                            number of arguments");
        return NULL;        
    }     
}

/*
 * frame_phyaddr([index])
 * 
 * just a wrapper of get_frame_phyaddr().
 */
static PyObject *videocapture_frame_phyaddr(videocaptureObject *self, 
                                            PyObject *args){
    unsigned int index = self->capture->curFrame;
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs == 0 || (nargs == 1 && PyArg_ParseTuple(args, "I", &index))){
        return get_frame_phyaddr(self->frame, index);
    }
    else {
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Invalid arguemnts or invalid \
                                            number of arguments");
        return NULL;        
    }     
}
/*****************************************************************************/
/* Defining the methods struct                                               */

static PyMethodDef videocapture_methods[] = {
    {"frame_index", (PyCFunction)videocapture_frame_index, METH_VARARGS,
     "Get current index or if the argument is specified set it to a new one \
      within the allowed range."
    },
    {"frame_index_next", (PyCFunction)videocapture_frame_index_next, 
     METH_VARARGS, "Set the frame index to the next one and return it."
    },
    {"frame_width", (PyCFunction)videocapture_frame_width, METH_VARARGS,
     "Get the current frame width."
    },
    {"frame_height", (PyCFunction)videocapture_frame_height, METH_VARARGS,
     "Get the current frame height."
    },
    {"start", (PyCFunction)videocapture_start, METH_VARARGS,
     "Start the video capture controller."
    },
    {"stop", (PyCFunction)videocapture_stop, METH_VARARGS,
     "Stop the video capture controller."
    },
    {"state", (PyCFunction)videocapture_state, METH_VARARGS,
     "Get the state of the video capture controller."
    },
    {"frame", (PyCFunction)videocapture_frame, METH_VARARGS,
     "Get the current frame (or the one at 'index' if specified)."
    },
    {"frame_addr", (PyCFunction)videocapture_frame_addr, METH_VARARGS,
     "Get the current frame buffer's address (or the one at 'index' if \
      specified)."
    },
    {"frame_phyaddr", (PyCFunction)videocapture_frame_phyaddr, METH_VARARGS,
     "Get the current frame buffer's physicals address (or the one at 'index' \
      if specified)."
    },
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* Defining the type object                                                  */

PyTypeObject videocaptureType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    "_video._capture",                          /* tp_name */
    sizeof(videocaptureObject),                 /* tp_basicsize */
    0,                                          /* tp_itemsize */
    (destructor)videocapture_dealloc,           /* tp_dealloc */
    0,                                          /* tp_print */
    0,                                          /* tp_getattr */
    0,                                          /* tp_setattr */
    0,                                          /* tp_reserved */
    0,                                          /* tp_repr */
    0,                                          /* tp_as_number */
    0,                                          /* tp_as_sequence */
    0,                                          /* tp_as_mapping */
    0,                                          /* tp_hash  */
    0,                                          /* tp_call */
    (reprfunc)videocapture_str,                 /* tp_str */
    0,                                          /* tp_getattro */
    0,                                          /* tp_setattro */
    0,                                          /* tp_as_buffer */
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,   /* tp_flags */
    "Video Capture object",                     /* tp_doc */
    0,                                          /* tp_traverse */
    0,                                          /* tp_clear */
    0,                                          /* tp_richcompare */
    0,                                          /* tp_weaklistoffset */
    0,                                          /* tp_iter */
    0,                                          /* tp_iternext */
    videocapture_methods,                       /* tp_methods */
    videocapture_members,                       /* tp_members */
    0,                                          /* tp_getset */
    0,                                          /* tp_base */
    0,                                          /* tp_dict */
    0,                                          /* tp_descr_get */
    0,                                          /* tp_descr_set */
    0,                                          /* tp_dictoffset */
    (initproc)videocapture_init,                /* tp_init */
    0,                                          /* tp_alloc */
    videocapture_new,                           /* tp_new */
};
