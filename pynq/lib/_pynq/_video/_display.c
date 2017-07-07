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
 * @file _display.c
 *
 * CPython bindings for a video display peripheral (video_display.h).
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
#include <string.h>
#include <stdlib.h>
#include <dlfcn.h>
#include "video_commons.h"
#include "video_display.h"
#include "_video.h"

typedef struct{
    PyObject_HEAD
    DisplayCtrl *display;
} videodisplayObject;

/*****************************************************************************/
/* Defining the dunder methods                                               */

/*
 * deallocator
 */
static void videodisplay_dealloc(videodisplayObject* self){
    DisplayStop(self->display);

    freeVirtualAddress(self->display->dynClkAddr);
    Py_Del_XVtc(self->display->vtc);
    free(self->display);
    Py_TYPE(self)->tp_free((PyObject*)self);

    char sysbuf[128];
	sprintf(sysbuf, "echo '_display del' >> /tmp/video.log");
	system(sysbuf);
}

/*
 * __new()__ method
 */
static PyObject *videodisplay_new(PyTypeObject *type, PyObject *args, 
                                  PyObject *kwds){
    char sysbuf[128];
	sprintf(sysbuf, "echo '_display new' >> /tmp/video.log");
	system(sysbuf);

    videodisplayObject *self;
    self = (videodisplayObject *)type->tp_alloc(type, 0);
    if((self->display = (DisplayCtrl *)malloc(sizeof(DisplayCtrl))) == NULL){
        PyErr_Format(PyExc_MemoryError, "Unable to allocate memory");
        return NULL;        
    }
    return (PyObject *)self;
}

/*
 * __init()__ method
 *
 * Python Constructor: display(vtcBaseAddress, dynClkAddress, fHdmi)
 */
static int videodisplay_init(videodisplayObject *self, PyObject *args){
    unsigned int vtcBaseAddress, dynClkAddress, fHdmi;
    if (!PyArg_ParseTuple(args, "III", &vtcBaseAddress, 
                          &dynClkAddress, &fHdmi))
        return -1;

    int status = DisplayInitialize(self->display, vtcBaseAddress, 
                                   dynClkAddress, fHdmi);

    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_LookupError, 
                     "_video._display initialization failed [%d]", status);
        return -1;
    }  
    return 0;
}


/*
 * __str()__ method
 */
static PyObject *videodisplay_str(videodisplayObject *self){
    char str[200];
    sprintf(str, "Video Dsiplay \r\n   State: %d \r\n Current Mode: %s", 
            self->display->state,
            self->display->vMode.label);
    return Py_BuildValue("s",str);
}

/*****************************************************************************/
/* Actual C bindings - member functions                                      */


/*
 * frame_width()
 * get current width
 */
static PyObject *videodisplay_frame_width(videodisplayObject *self){
    return Py_BuildValue("I", self->display->vMode.width);
}

/*
 * frame_height()
 * get current height
 */
static PyObject *videodisplay_frame_height(videodisplayObject *self){
    return Py_BuildValue("I", self->display->vMode.height);
}

/*
 * start()
 */
static PyObject *videodisplay_start(videodisplayObject *self){
    int status = DisplayStart(self->display);
    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_SystemError, 
                     "Unable to start display device [%d]", status);
        return NULL;
    }
    Py_RETURN_NONE;
}

/*
 * stop()
 */
static PyObject *videodisplay_stop(videodisplayObject *self){
    int status = DisplayStop(self->display);
    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_SystemError, 
                     "Unable to stop display device [%d]", status);
        return NULL;
    }
    Py_RETURN_NONE;
}

/*
 * state()
 */
static PyObject *videodisplay_state(videodisplayObject *self){
    return Py_BuildValue("I", self->display->state);
}

/*
 * mode([new_mode_index])
 * return current mode label, and set a new one if new_mode_index is specified
 */
static PyObject *videodisplay_mode(videodisplayObject *self, 
                                          PyObject *args){
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs > 0){
        unsigned int new_mode;
        if (!PyArg_ParseTuple(args, "I", &new_mode))
            return NULL;
        switch(new_mode){
            case 0:
                DisplaySetMode(self->display, &VMODE_640x480);
                break;
            case 1:
                DisplaySetMode(self->display, &VMODE_800x600);
                break;
            case 2:
                DisplaySetMode(self->display, &VMODE_1280x720);
                break;
            case 3:
                DisplaySetMode(self->display, &VMODE_1280x1024);
                break;
            case 4:
                DisplaySetMode(self->display, &VMODE_1920x1080);
                break;
            default:
                PyErr_Format(PyExc_ValueError, 
                             "New mode index out of range [%d,%d]",
                             0, 4);    
                return NULL;
        }         
    }
    return Py_BuildValue("s", self->display->vMode.label);
}


/*****************************************************************************/
/* Defining the methods struct                                               */

static PyMethodDef videodisplay_methods[] = {
    {"frame_width", (PyCFunction)videodisplay_frame_width, METH_VARARGS,
     "Get the current frame width."
    },
    {"frame_height", (PyCFunction)videodisplay_frame_height, METH_VARARGS,
     "Get the current frame height."
    },
    {"start", (PyCFunction)videodisplay_start, METH_VARARGS,
     "Start the display controller."
    },
    {"stop", (PyCFunction)videodisplay_stop, METH_VARARGS,
     "Stop the display controller."
    },
    {"state", (PyCFunction)videodisplay_state, METH_VARARGS,
     "Get the state of the display controller."
    },
    {"mode", (PyCFunction)videodisplay_mode, METH_VARARGS,
     "Return current mode label, and set a new one if new_mode_index \
      is specified."
    },
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* Defining the type object                                                  */

PyTypeObject videodisplayType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    "_video._display",                          /* tp_name */
    sizeof(videodisplayObject),                 /* tp_basicsize */
    0,                                          /* tp_itemsize */
    (destructor)videodisplay_dealloc,           /* tp_dealloc */
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
    (reprfunc)videodisplay_str,                 /* tp_str */
    0,                                          /* tp_getattro */
    0,                                          /* tp_setattro */
    0,                                          /* tp_as_buffer */
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,   /* tp_flags */
    "Video Display object",                     /* tp_doc */
    0,                                          /* tp_traverse */
    0,                                          /* tp_clear */
    0,                                          /* tp_richcompare */
    0,                                          /* tp_weaklistoffset */
    0,                                          /* tp_iter */
    0,                                          /* tp_iternext */
    videodisplay_methods,                       /* tp_methods */
    0,                                          /* tp_members */
    0,                                          /* tp_getset */
    0,                                          /* tp_base */
    0,                                          /* tp_dict */
    0,                                          /* tp_descr_get */
    0,                                          /* tp_descr_set */
    0,                                          /* tp_dictoffset */
    (initproc)videodisplay_init,                /* tp_init */
    0,                                          /* tp_alloc */
    videodisplay_new,                           /* tp_new */
};
