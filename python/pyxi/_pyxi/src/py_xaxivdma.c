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
 * CPython interface for XAxiVdma.
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   26 JAN 2016
 */

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
            if(--py_axivdmas.refCnt[i] == 0){//can delete as nobody is using it
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
