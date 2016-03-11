/*
 * CPython interface for XGpio.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#ifndef __PY_XGPIO_H__
#define __PY_XGPIO_H__ 

#include <Python.h>
#include "utils.h"
#include "xgpio.h"

XGpio_Config Py_XGpio_LookupConfig(PyObject *gpio_dict);
XGpio *Py_XGpio_CfgInitialize(XGpio_Config *cfg);
void Py_Del_XGpio(XGpio *gpio);

#endif // __PY_XGPIO_H__