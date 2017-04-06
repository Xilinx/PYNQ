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
    videoframeObject *frame;
} videodisplayObject;

/*****************************************************************************/
/* Defining the dunder methods                                               */

/*
 * deallocator
 */
static void videodisplay_dealloc(videodisplayObject* self){
    DisplayStop(self->display);

    freeVirtualAddress(self->display->dynClkAddr);
    Py_Del_XAxiVdma(self->display->vdma);
    Py_Del_XVtc(self->display->vtc);
    free(self->display);
    Py_TYPE(self)->tp_free((PyObject*)self);

    for(int i = 0; i < NUM_FRAMES; i++)
        cma_free(self->frame->frame_buffer[i]);

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
 * Python Constructor: display(vdma_dict, vtcBaseAddress, dynClkAddress, 
 *                             fHdmi, [video.frame])
 */
static int videodisplay_init(videodisplayObject *self, PyObject *args){
    self->frame = NULL;
    PyObject *vdma_dict = NULL;
    unsigned int vtcBaseAddress, dynClkAddress, fHdmi;
    if (!PyArg_ParseTuple(args, "OIII|O", &vdma_dict, &vtcBaseAddress, 
                          &dynClkAddress, &fHdmi, &self->frame))
        return -1;
    if (!PyDict_Check(vdma_dict))
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

    int status = DisplayInitialize(self->display, vdma_dict, vtcBaseAddress, 
                                   dynClkAddress, fHdmi, 
                                   self->frame->frame_buffer, STRIDE);
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
    sprintf(str, "Video Dsiplay \r\n   State: %d \r\n   \
                  Current Index: %d \r\n   Current Mode: %s", 
            self->display->state, self->display->curFrame, 
            self->display->vMode.label);
    return Py_BuildValue("s",str);
}

/*
 * exposing members
 */
static PyMemberDef videodisplay_members[] = {
    {"framebuffer", T_OBJECT, offsetof(videodisplayObject, frame), READONLY,
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
static PyObject *videodisplay_frame_index(videodisplayObject *self, 
                                          PyObject *args){
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs > 0){
        unsigned int newIndex = 0;
        if (!PyArg_ParseTuple(args, "I", &newIndex))
            return NULL;
        if(newIndex >= 0 && newIndex < NUM_FRAMES){       
            self->display->curFrame = newIndex;
            int status = DisplayChangeFrame(self->display, newIndex);
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
    return Py_BuildValue("I", self->display->curFrame);
}


/*
 * frame_index_next()
 * Set the frame index to the next one and return it
 */
static PyObject *videodisplay_frame_index_next(videodisplayObject *self){
    unsigned int newIndex = self->display->curFrame + 1;
     if(newIndex >= NUM_FRAMES)
        newIndex = 0;         
    int status = DisplayChangeFrame(self->display, newIndex);   
    if (status != XST_SUCCESS){
        PyErr_Format(PyExc_SystemError, 
                     "Unable to change frame [%d]", status);
        return NULL;
    }
    return Py_BuildValue("I", self->display->curFrame);
}

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

/*
 * frame([index], [new_frame])
 * 
 * just a wrapper of get_frame() and set_frame() defined for the videoframe
 * object.
 */
static PyObject *videodisplay_frame(videodisplayObject *self, PyObject *args){
    unsigned int index = self->display->curFrame;
    PyObject *new_frame = NULL;
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs == 0 || (nargs == 1 && PyArg_ParseTuple(args, "I", &index))){
        return get_frame(self->frame, index);
    }
    if(nargs == 1 && !PyArg_ParseTuple(args, "O", &new_frame)){
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Passed argument is invalid");
        return NULL;        
    }
    else if(nargs == 2 && !PyArg_ParseTuple(args, "IO", &index, &new_frame)){
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Passed arguments are invalid");
        return NULL;        
    }
    else if(nargs > 2){
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Invalid number of arguments");
        return NULL;        
    }
    if (!PyByteArray_CheckExact(new_frame)){
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, 
                        "new_frame argument must be a bytearray");
        return NULL;
    }       
    PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
    return set_frame(self->frame, index, (PyByteArrayObject *)new_frame);
}

/*
 * frame_addr([index])
 * 
 * just a wrapper of get_frame_addr().
 */
static PyObject *videodisplay_frame_addr(videodisplayObject *self, PyObject *args){
    unsigned int index = self->display->curFrame;
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs == 0 || (nargs == 1 && PyArg_ParseTuple(args, "I", &index))){
        return get_frame_addr(self->frame, index);
    }
    else {
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Invalid arguemnts or invalid number of arguments");
        return NULL;        
    }     
}

/*
 * frame_phyaddr([index])
 * 
 * just a wrapper of get_frame_phyaddr().
 */
static PyObject *videodisplay_frame_phyaddr(videodisplayObject *self, PyObject *args){
    unsigned int index = self->display->curFrame;
    Py_ssize_t nargs = PyTuple_Size(args);
    if(nargs == 0 || (nargs == 1 && PyArg_ParseTuple(args, "I", &index))){
        return get_frame_phyaddr(self->frame, index);
    }
    else {
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Invalid arguemnts or invalid number of arguments");
        return NULL;        
    }     
}
/*****************************************************************************/
/* Defining the methods struct                                               */

static PyMethodDef videodisplay_methods[] = {
    {"frame_index", (PyCFunction)videodisplay_frame_index, METH_VARARGS,
     "Get current index or if the argument is specified set it to a new one \
      within the allowed range."
    },
    {"frame_index_next", (PyCFunction)videodisplay_frame_index_next, METH_VARARGS,
     "Set the frame index to the next one and return it."
    },
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
    {"frame", (PyCFunction)videodisplay_frame, METH_VARARGS,
     "Get the current frame (or the one at 'index' if specified) or set \
      the frame if 'new_frame' is specified."
    },
    {"frame_addr", (PyCFunction)videodisplay_frame_addr, METH_VARARGS,
     "Get the current frame buffer's address (or the one at 'index' if specified)."
    },
    {"frame_phyaddr", (PyCFunction)videodisplay_frame_phyaddr, METH_VARARGS,
     "Get the current frame buffers's physical address (or the one at 'index' if specified)."
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
    videodisplay_members,                       /* tp_members */
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
