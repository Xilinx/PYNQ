/*
 * @author Giuseppe Natale
 * @date   27 JAN 2016
 */


#include <Python.h>
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
