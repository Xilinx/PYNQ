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
 * @file _framebuffer.c
 *
 * CPython bindings for a video framebuffer object
 * to be used in conjunction with frambuffer.py driver
 *
 * The file is used to create buffers in memory that can be shared between
 *  Kernel space and userspace. The buffer is available to the use in a
 *  bytearray format.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a dm  03/19/17 release
 *
 * </pre>
 *
 *****************************************************************************/

#include <Python.h>
#include <structmember.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xil_types.h"
#include "video_commons.h"
#include "_video.h"
#include <stdint.h>

#define DEFAULT_COLOR_DEPTH 3

/*****************************************************************************/
/* Defining the dunder methods                                               */

/*
 * deallocator
 */
static void framebuffer_dealloc(framebufferObject* self)
{
    cma_free(self->frame_buffer);
    Py_TYPE(self)->tp_free((PyObject*)self);

    char sysbuf[128];
	sprintf(sysbuf, "echo '_frame del' >> /tmp/video.log");
	system(sysbuf);
}

/*
 * __new()__ method
 */
static PyObject *framebuffer_new(PyTypeObject *type, PyObject *args,
                                  PyObject *kwds)
{
    char sysbuf[128];
	sprintf(sysbuf, "echo '_display new' >> /tmp/video.log");
	system(sysbuf);

    framebufferObject *self;
    self = (framebufferObject *)type->tp_alloc(type, 0);
    return (PyObject *)self;
}

/*
 * __init()__ method
 *
 * Python Constructor: frame([single_frame])
 * set single_frame to 1 if you want this object to hold a single frame
 * (that will be available at index 0)
 */
static int framebuffer_init(framebufferObject *self, PyObject *args)
{
    self->width = 0;
    self->height = 0;
    self->color_depth = DEFAULT_COLOR_DEPTH;
    self->size = 0;

    if (!PyArg_ParseTuple(args, "II|I", &self->width, &self->height,
        &self->color_depth))
        return -1;

    self->size = self->width * self->height * self->color_depth;
    if ((self->frame_buffer = (u8 *)cma_alloc(sizeof(u8) * self->size, 0))
          == NULL) {
        PyErr_Format(PyExc_MemoryError,"Unable to allocate memory");
        return -1;

    }
    return 0;
}

/*
 * exposing members:
 *  width: Width of the image
 *  height: Height of the image
 *  color_depth: Number of bytes a single pixel required (normally 3 for
 *      RGB)
 *  size: Total number of bytes the framebuffer holds
 */
static PyMemberDef framebuffer_members[] =
{
    {"width", T_UINT, offsetof(framebufferObject, width),READONLY,
     "width of the image"},
    {"height", T_UINT, offsetof(framebufferObject, height),READONLY,
     "height of the image"},
    {"color_depth", T_UINT, offsetof(framebufferObject, color_depth),READONLY,
     "number of bytes per pixel"},
    {"size", T_UINT, offsetof(framebufferObject, size),READONLY,
     "total size of the image (in bytes) = width * height * color_depth"},
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* functions used to set or get a frame or get (physical) frame address      */
/* used by the frame member functions and by _capture.c and _display.c       */

/*
 * get a physical frame address as long
 *
 * The physical address is accessable by the FPGA. Giving the normal address
 * of the framebuffer (E.G. &self->framebuffer[0]) would cause the kernel to
 * freeze because that address is virtual (only relevant for the user
 * application). The kernel does some address mangling in order to allow
 * users to work with comfortable address spaces like 0x00000000 but if that
 * virtual address was passed to the kernel the FPGA may try and access
 * memory at an illegal address space. If so there is no 'segfault' that would
 * protect the kernel, instead the kernel may actually write to that space and
 * cause the kernel to be unstable.
 *
 *
 */
PyObject *get_framebuffer_phyaddr(framebufferObject *self)
{
    unsigned int ret = cma_get_phy_addr(self->frame_buffer);
    return PyLong_FromUnsignedLong(ret);
}

/*
 * get a bytearray of the framebuffer
 */
PyObject *get_framebuffer(framebufferObject *self)
{
    return PyByteArray_FromStringAndSize((char *)self->frame_buffer,
        self->width * self->height * self->color_depth);
}

/*
 * set the framebuffer values
 */
PyObject *set_framebuffer(framebufferObject *self,
                                  PyByteArrayObject *new_frame)
{
    if(PyByteArray_Size((PyObject *)new_frame) != ((int32_t) self->size)){
        PyErr_Format(PyExc_ValueError,
                     "new_frame bytearray must have %d number of elements",
                     self->size);
        return NULL;
    }
    memcpy(self->frame_buffer, new_frame->ob_start, self->size);
    Py_RETURN_NONE;
}

/*****************************************************************************/
/* Actual C bindings - member functions
 * This is how Python interfaces with the C functions
 */

PyObject *framebuffer_call(framebufferObject *self, PyObject *args,
                                 PyObject *kw){
    PyObject *new_frame = NULL;
    if (!PyArg_ParseTuple(args, "|O", &new_frame))
        return NULL;

    if(new_frame != NULL){ // set mode
        if (!PyByteArray_CheckExact(new_frame)){
            PyErr_SetString(PyExc_SyntaxError,
                            "new_frame argument must be a bytearray");
            return NULL;
        }
        return set_framebuffer(self, (PyByteArrayObject *)new_frame);
    }
    else // get mode
        return get_framebuffer(self);
}

static PyObject *framebuffer_get_phy_addr(framebufferObject *self,
                            PyObject *args, PyObject *kw) {
    unsigned int ret = cma_get_phy_addr(self->frame_buffer);
    return PyLong_FromUnsignedLong(ret);
}

/*
 * frame([new_frame])
 *
 * just a wrapper of get_framebuffer() and set_framebuffer() defined for the
 * framebuffer object.
 *
 *  If no parameters are passed to the the function it will return
 *  a python object bytearray
 *
 *  If a new frame is passed in as a bytearray, it is copied to the memory
 *  space
 *
 */
static PyObject *framebuffer_frame(framebufferObject *self,
      PyObject *args){
    PyObject *new_frame = NULL;
    Py_ssize_t nargs = PyTuple_Size(args);

    //Get Buffer
    if (nargs == 0) {
        return get_framebuffer(self);
    }

    //Set Buffer
    if(nargs == 1 && !PyArg_ParseTuple(args, "O", &new_frame)){
        PyErr_Clear(); //clear possible exception set by PyArg_ParseTuple
        PyErr_SetString(PyExc_SyntaxError, "Passed argument is invalid");
        return NULL;
    }
    else if(nargs > 1){
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
    return set_framebuffer(self, (PyByteArrayObject *)new_frame);
}

/*****************************************************************************/
/* Defining the methods struct                                               */

static PyMethodDef framebuffer_methods[] = {
    {"get_phy_address", (PyCFunction)framebuffer_get_phy_addr, METH_VARARGS,
     "Gets the physical address, used to interface with DMA and VDMA."
    },

    {"frame_raw", (PyCFunction)framebuffer_frame, METH_VARARGS,
     "Get the frame the frame if 'new_frame' is specified."
    },
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* Defining the type object                                                  */

PyTypeObject framebufferType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    "_video._frame",                            /* tp_name */
    sizeof(framebufferObject),                   /* tp_basicsize */
    0,                                          /* tp_itemsize */
    (destructor)framebuffer_dealloc,             /* tp_dealloc */
    0,                                          /* tp_print */
    0,                                          /* tp_getattr */
    0,                                          /* tp_setattr */
    0,                                          /* tp_reserved */
    0,                                          /* tp_repr */
    0,                                          /* tp_as_number */
    0,                                          /* tp_as_sequence */
    0,                                          /* tp_as_mapping */
    0,                                          /* tp_hash  */
    (ternaryfunc)framebuffer_call,               /* tp_call */
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
    framebuffer_methods,                         /* tp_methods */
    framebuffer_members,                         /* tp_members */
    0,                                          /* tp_getset */
    0,                                          /* tp_base */
    0,                                          /* tp_dict */
    0,                                          /* tp_descr_get */
    0,                                          /* tp_descr_set */
    0,                                          /* tp_dictoffset */
    (initproc)framebuffer_init,                  /* tp_init */
    0,                                          /* tp_alloc */
    framebuffer_new,                             /* tp_new */
};

