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
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   27 JAN 2016
 */

#include <Python.h>         //pulls the Python API

#include "_video.h"

static PyModuleDef _videomodule = {
    PyModuleDef_HEAD_INIT,
    "_video",
    "Implements C bindings for the video part of the AV overlay.",
    -1,
    NULL, NULL, NULL, NULL, NULL
};

PyMODINIT_FUNC PyInit__video(void){
    PyObject* m;

    if (PyType_Ready(&videoframeType) < 0)
        return NULL;
    if (PyType_Ready(&videodisplayType) < 0)
        return NULL;
    if (PyType_Ready(&videocaptureType) < 0)
        return NULL;

    m = PyModule_Create(&_videomodule);
    if (m == NULL)
        return NULL;

    Py_INCREF(&videoframeType);
    Py_INCREF(&videodisplayType);
    Py_INCREF(&videocaptureType);
    PyModule_AddObject(m, "_frame", (PyObject *)&videoframeType);
    PyModule_AddObject(m, "_display", (PyObject *)&videodisplayType);
    PyModule_AddObject(m, "_capture", (PyObject *)&videocaptureType);
    return m;
}
