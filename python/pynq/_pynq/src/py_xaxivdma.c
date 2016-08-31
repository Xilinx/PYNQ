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
 * @file py_xaxivdma.c
 *
 * CPython interface for XAxiVdma.
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
#include "py_xaxivdma.h"

Array py_axivdmas = {.size = -1};


XAxiVdma_Config Py_XAxiVdma_LookupConfig(PyObject *vdma_dict){
    XAxiVdma_Config config =
    {
        0,
        getVirtualAddress(PyDict_GetUintString(vdma_dict, "BASEADDR")),
        PyDict_GetUintString(vdma_dict, "NUM_FSTORES"),
        PyDict_GetUintString(vdma_dict, "INCLUDE_MM2S"),
        PyDict_GetUintString(vdma_dict, "INCLUDE_MM2S_DRE"),
        PyDict_GetUintString(vdma_dict, "M_AXI_MM2S_DATA_WIDTH"),
        PyDict_GetUintString(vdma_dict, "INCLUDE_S2MM"),
        PyDict_GetUintString(vdma_dict, "INCLUDE_S2MM_DRE"),
        PyDict_GetUintString(vdma_dict, "M_AXI_S2MM_DATA_WIDTH"),
        PyDict_GetUintString(vdma_dict, "INCLUDE_SG"),
        PyDict_GetUintString(vdma_dict, "ENABLE_VIDPRMTR_READS"),
        PyDict_GetUintString(vdma_dict, "USE_FSYNC"),
        PyDict_GetUintString(vdma_dict, "FLUSH_ON_FSYNC"),
        PyDict_GetUintString(vdma_dict, "MM2S_LINEBUFFER_DEPTH"),
        PyDict_GetUintString(vdma_dict, "S2MM_LINEBUFFER_DEPTH"),
        PyDict_GetUintString(vdma_dict, "MM2S_GENLOCK_MODE"),
        PyDict_GetUintString(vdma_dict, "S2MM_GENLOCK_MODE"),
        PyDict_GetUintString(vdma_dict, "INCLUDE_INTERNAL_GENLOCK"),
        PyDict_GetUintString(vdma_dict, "S2MM_SOF_ENABLE"),
        PyDict_GetUintString(vdma_dict, "M_AXIS_MM2S_TDATA_WIDTH"),
        PyDict_GetUintString(vdma_dict, "S_AXIS_S2MM_TDATA_WIDTH"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_1"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_5"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_6"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_7"),       
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_9"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_13"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_14"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_INFO_15"),
        PyDict_GetUintString(vdma_dict, "ENABLE_DEBUG_ALL"),
        PyDict_GetUintString(vdma_dict, "ADDR_WIDTH")    
    };
    return config;
}


XAxiVdma *Py_XAxiVdma_CfgInitialize(XAxiVdma_Config *cfg){
    if(py_axivdmas.size == -1)
        initArray(&py_axivdmas, 1);

    for(int i = 0; i < py_axivdmas.used; i++){
        XAxiVdma *curr = (XAxiVdma *)py_axivdmas.array[i];
        if(curr->BaseAddr == cfg->BaseAddress){
            //increment reference count and return element
            py_axivdmas.refCnt[i]++;
            return curr; 
        }
    }

    XAxiVdma *newVdma = (XAxiVdma *)malloc(sizeof(XAxiVdma));
    int Status = XAxiVdma_CfgInitialize(newVdma, cfg, cfg->BaseAddress);
    if (Status != XST_SUCCESS){
        PyErr_SetString(PyExc_LookupError, "Failed to Initialize XAxiVdma");
        return NULL;
    }
    appendElemArray(&py_axivdmas, (ptr)newVdma);
    return newVdma;
}

void Py_Del_XAxiVdma(XAxiVdma *vdma){
    for(int i = 0; i < py_axivdmas.used; i++){
        XAxiVdma *curr = (XAxiVdma *)py_axivdmas.array[i];
        if(curr->BaseAddr == vdma->BaseAddr){
            if(--py_axivdmas.refCnt[i] == 0){
                for(int j = i; j < py_axivdmas.used-1; j++){
                    py_axivdmas.array[j] = py_axivdmas.array[j+1];
                    py_axivdmas.refCnt[j] = py_axivdmas.refCnt[j+1];
                }
                py_axivdmas.used--;
                freeVirtualAddress(curr->BaseAddr);
                free(curr);
            }
        }  
    }    
}
