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
 * @file py_xgpio.c
 *
 * CPython interface for XGpio.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a gn  01/26/16 release
 * 1.00b yrq 08/31/16 add license header
 *
 * </pre>
 *
 *****************************************************************************/

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
            if(--py_gpios.refCnt[i] == 0){
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
