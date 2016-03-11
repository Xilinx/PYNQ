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
