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
 * @file py_xvtc.c
 *
 * CPython interface for XVtc.
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
            if(--py_vtcs.refCnt[i] == 0){
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