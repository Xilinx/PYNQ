/******************************************************************************
*
* Copyright (C) 2010 - 2015 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* XILINX CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * CPython bindings for an audio peripheral (audio.h)
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#include <Python.h>         //pulls the Python API
#include <structmember.h>   //handle attributes
 
#include <stdio.h>
#include <stdlib.h>

#include "gpio.h"
#include "utils.h"
#include "audio.h"
#include "xil_io.h"
//#include "py_xiicps.h"


typedef struct {
    PyObject_HEAD
    unsigned int baseaddr;
    unsigned int emioPin;
//    XIicPs *iic;
    int iic;
    int muted;
} _audioObject;


/*****************************************************************************/
/* Defining OOP special methods                                              */

/*
 * deallocator
 */
static void _audio_dealloc(_audioObject* self){
    //freeVirtualAddress(self->iic->Config.BaseAddress);
    //Py_Del_XIicPs(self->iic);

    freeVirtualAddress(self->baseaddr);
    unsetGpio(self->emioPin);
    Py_TYPE(self)->tp_free((PyObject*)self);
}

/*print
 * __init()__ method
 *
 * Python Constructor: audio(baseaddr, emio_pin, iicps_idx)
 */
static int _audio_init(_audioObject *self, PyObject *args){
    /*PyObject *iicps_dict = NULL;
    if (!PyArg_ParseTuple(args, "IIO", &self->baseaddr, &self->emioPin,
                          &iicps_dict))
        return -1;
    if (!PyDict_CheckExact(iicps_dict))
        return -1;*/
    if (!PyArg_ParseTuple(args, "III", &self->baseaddr, &self->emioPin,
                          &self->iic))
        return -1;
    setGpio(self->emioPin, "out");
    writeGpio(self->emioPin, 1); // unmute audio CODEC
    self->muted = 0;
    self->baseaddr = getVirtualAddress(self->baseaddr);
    //self->iic = IicConfig(iicps_dict);
    LineinLineoutConfig(self->iic);   
    return 0;
}

/*
 * __str()__ method
 */
static PyObject *_audio_str(_audioObject *self){
    char str[200];
    char *state = self->muted? "Muted":"Unmuted";
    sprintf(str,"Audio Controller\r\n   I2S MemAddr: 0x%x \r\n   \
            GPIO Pin: %d \r\n   State: %s I2C id: %d", 
            self->baseaddr, self->emioPin, state, self->iic);
    return Py_BuildValue("s",str);
}

/*
 * exposing members
 */
static PyMemberDef _audio_members[] = {
    {"baseaddr", T_UINT, offsetof(_audioObject, baseaddr), READONLY,
     "base address"},
    {"emioPin", T_UINT, offsetof(_audioObject, emioPin), READONLY,
     "EMIO Pin"},
    {"muted", T_UINT, offsetof(_audioObject, muted), READONLY,
     "1:muted, 0:unmuted"},
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* Actual C bindings - member functions                                      */

/*
 * input()
 * get the current content of both the L and R channel as a list = (L,R)
 */
static PyObject *_audio_input(_audioObject *self){
    u32 wait;
    PyObject *channels = PyList_New(0);    
    do //wait for RX data to become available
    {
        wait = Xil_In32(I2S_STATUS_OFFSET + self->baseaddr);
    }while ( wait == 0);
    Xil_Out32(I2S_STATUS_OFFSET + self->baseaddr, 0x00000001); //Clear data rdy bit
    PyList_Append(channels, Py_BuildValue("I", Xil_In32(I2S_DATA_RX_L_OFFSET
                                                        + self->baseaddr)));
    PyList_Append(channels, Py_BuildValue("I", Xil_In32(I2S_DATA_RX_R_OFFSET
                                                        + self->baseaddr)));
    return channels;
}


/*
 * output()
 * take a list = (L,R) and outputs the value on both the left and right 
 * channels
 */
static PyObject *_audio_output(_audioObject *self, PyObject *args){
    PyObject *channels = NULL;
    if (! PyArg_ParseTuple(args, "O", &channels))
        return NULL;
    if (! PyList_Check(channels) || 
        (PyList_Check(channels) && (PyList_Size(channels) != 2))){
        PyErr_SetString(PyExc_SyntaxError, 
                        "Channels argument is not a valid list [L,R]");
        return NULL;
    }
    u32 l_ch = (u32)PyLong_AsLong(PyList_GetItem(channels, 0));
    u32 r_ch = (u32)PyLong_AsLong(PyList_GetItem(channels, 1));
    Xil_Out32(I2S_DATA_TX_L_OFFSET + self->baseaddr, l_ch);
    Xil_Out32(I2S_DATA_TX_R_OFFSET + self->baseaddr, r_ch);  
    Py_RETURN_NONE;  
}

/*
 * toggle_mute()
 * mute/unmute the audio codec
 */
static PyObject *_audio_toggle_mute(_audioObject *self){
    if(self->muted == 1){
        // unmute audio CODEC
        writeGpio(self->emioPin, 1);
        self->muted = 0;
    }
    else{
        // mute audio CODEC
        writeGpio(self->emioPin, 0);
        self->muted = 1;        
    }    
    Py_RETURN_NONE;
}


/*****************************************************************************/

/*
 * defining the methods
 *
 */
static PyMethodDef _audio_methods[] = {
    {"input", (PyCFunction)_audio_input, METH_VARARGS,
     "Get the current content of both the L and R channel as a list = (L,R)."
    },
    {"output", (PyCFunction)_audio_output, METH_VARARGS,
     "Take a list = (L,R) and outputs the value on both the left and \
      right channels."
    },
    {"toggle_mute", (PyCFunction)_audio_toggle_mute, METH_VARARGS,
     "Mute/unmute the audio codec."
    },
    {NULL}  /* Sentinel */
};

/*****************************************************************************/
/* Defining the type object                                                  */

static PyTypeObject _audioType = {
    PyVarObject_HEAD_INIT(&PyType_Type, 0)
    "_audio._audio",                            /* tp_name */
    sizeof(_audioObject),                       /* tp_basicsize */
    0,                                          /* tp_itemsize */
    (destructor)_audio_dealloc,                 /* tp_dealloc */
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
    (reprfunc)_audio_str,                       /* tp_str */
    0,                                          /* tp_getattro */
    0,                                          /* tp_setattro */
    0,                                          /* tp_as_buffer */
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,   /* tp_flags */
    "Audio objects for the AV overlay",         /* tp_doc */
    0,                                          /* tp_traverse */
    0,                                          /* tp_clear */
    0,                                          /* tp_richcompare */
    0,                                          /* tp_weaklistoffset */
    0,                                          /* tp_iter */
    0,                                          /* tp_iternext */
    _audio_methods,                             /* tp_methods */
    _audio_members,                             /* tp_members */
    0,                                          /* tp_getset */
    0,                                          /* tp_base */
    0,                                          /* tp_dict */
    0,                                          /* tp_descr_get */
    0,                                          /* tp_descr_set */
    0,                                          /* tp_dictoffset */
    (initproc)_audio_init,                      /* tp_init */
    PyType_GenericAlloc,                        /* tp_alloc */
    PyType_GenericNew,                          /* tp_new */
};

/*****************************************************************************/
/* Creating the wrapping module                                              */

static PyModuleDef _audiomodule = {
    PyModuleDef_HEAD_INIT,
    "_audio",
    "Implements C bindings for the audio part of the AV overlay.",
    -1,
    NULL, NULL, NULL, NULL, NULL
};

PyMODINIT_FUNC PyInit__audio(void){
    PyObject* m;

    if (PyType_Ready(&_audioType) < 0)
        return NULL;

    m = PyModule_Create(&_audiomodule);
    if (m == NULL)
        return NULL;

    Py_INCREF(&_audioType);
    PyModule_AddObject(m, "_audio", (PyObject *)&_audioType);
    return m;
}
