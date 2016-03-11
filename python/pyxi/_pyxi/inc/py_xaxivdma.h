/*
 * CPython interface for XAxiVdma.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#ifndef __PY_XAXIVDMA_H__
#define __PY_XAXIVDMA_H__

#include <Python.h>
#include "utils.h"
#include "xaxivdma.h"

XAxiVdma_Config Py_XAxiVdma_LookupConfig(PyObject *vdma_dict);
XAxiVdma *Py_XAxiVdma_CfgInitialize(XAxiVdma_Config *cfg);
void Py_Del_XAxiVdma(XAxiVdma *vdma);

#endif // __PY_XAXIVDMA_H__
