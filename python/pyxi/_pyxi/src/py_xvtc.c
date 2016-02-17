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
 * CPython interface for XVtc.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

#include <stdlib.h>
#include "py_xvtc.h"

Array py_vtcs = {.size = -1};

XVtc_Config Py_XVtc_LookupConfig(unsigned int vtc_baseaddr){
    XVtc_Config config =
    {
        0,
        getVirtualAddress(vtc_baseaddr)
    };
    return config;
}


XVtc *Py_XVtc_CfgInitialize(XVtc_Config *cfg){
    if(py_vtcs.size == -1)
        initArray(&py_vtcs, 1);

    for(int i = 0; i < py_vtcs.used; i++){
        XVtc *curr = (XVtc *)py_vtcs.array[i];
        if(curr->Config.BaseAddress == cfg->BaseAddress)
            return curr;
    }
    
    XVtc *newVtc = (XVtc *)malloc(sizeof(XVtc));
    int Status = XVtc_CfgInitialize(newVtc, cfg, cfg->BaseAddress);
    if (Status != XST_SUCCESS){
        PyErr_SetString(PyExc_LookupError, "Failed to Initialize XVtc");
        return NULL;
    }
    appendElemArray(&py_vtcs, (ptr)newVtc);   
    return newVtc;
}

void Py_Del_XVtc(XVtc *vtc){
    for(int i = 0; i < py_vtcs.used; i++){
        XVtc *curr = (XVtc *)py_vtcs.array[i];
        if(curr->Config.BaseAddress == vtc->Config.BaseAddress){
            if(--py_vtcs.refCnt[i] == 0){ //can delete as nobody is using it
                for(int j = i; j < py_vtcs.used-1; j++){
                    py_vtcs.array[j] = py_vtcs.array[j+1];
                    py_vtcs.refCnt[j] = py_vtcs.refCnt[j+1];
                }
                py_vtcs.used--;
                freeVirtualAddress(curr->Config.BaseAddress);
                free(curr);
            }
        }  
    }    
}