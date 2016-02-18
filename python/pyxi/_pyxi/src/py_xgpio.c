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
 * CPython interface for XGpio.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#include <stdlib.h>
#include "py_xgpio.h"

Array py_gpios = {.size = -1};


XGpio_Config Py_XGpio_LookupConfig(PyObject *gpio_dict){
    XGpio_Config config =
    {
        0,
        getVirtualAddress(PyDict_GetUintString(gpio_dict, "BASEADDR")),
        PyDict_GetUintString(gpio_dict, "INTERRUPT_PRESENT"),
        PyDict_GetUintString(gpio_dict, "IS_DUAL")
    };
    return config;
}


XGpio *Py_XGpio_CfgInitialize(XGpio_Config *cfg){
    if(py_gpios.size == -1)
        initArray(&py_gpios, 1);

    for(int i = 0; i < py_gpios.used; i++){
        XGpio *curr = (XGpio *)py_gpios.array[i];
        if(curr->BaseAddress == cfg->BaseAddress){
            //increment reference count and return element
            py_gpios.refCnt[i]++;
            return curr; 
        }
    }

    XGpio *newGpio = (XGpio *)malloc(sizeof(XGpio));
    int Status = XGpio_CfgInitialize(newGpio, cfg, cfg->BaseAddress);
    if (Status != XST_SUCCESS){
        PyErr_SetString(PyExc_LookupError, "Failed to Initialize XGpio");
        return NULL;
    }
    appendElemArray(&py_gpios, (ptr)newGpio);   
    return newGpio;
}

void Py_Del_XGpio(XGpio *gpio){
    for(int i = 0; i < py_gpios.used; i++){
        XGpio *curr = (XGpio *)py_gpios.array[i];
        if(curr->BaseAddress == gpio->BaseAddress){
            if(--py_gpios.refCnt[i] == 0){ //can delete as nobody is using it
                for(int j = i; j < py_gpios.used-1; j++){
                    py_gpios.array[j] = py_gpios.array[j+1];
                    py_gpios.refCnt[j] = py_gpios.refCnt[j+1];
                }
                py_gpios.used--;
                freeVirtualAddress(curr->BaseAddress);
                free(curr);
            }
        }  
    }    
}
