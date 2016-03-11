/*
 * CPython interface for XVtc.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#ifndef __PY_XVTC_H__
#define __PY_XVTC_H__ 

#include <Python.h>
#include "utils.h"
#include "xvtc.h"

XVtc_Config Py_XVtc_LookupConfig(unsigned int vtc_baseaddr);
XVtc *Py_XVtc_CfgInitialize(XVtc_Config *cfg);
void Py_Del_XVtc(XVtc *vtc);

#endif // __PY_XVTC_H__