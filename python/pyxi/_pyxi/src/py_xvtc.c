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