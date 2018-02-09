#include <intrgpio.h>

extern IntrGpio_Config IntrGpio_ConfigTable[];

void IntrGpio_RaiseInterrupt(int ID) {
    volatile unsigned int* ptr = (volatile unsigned int*)IntrGpio_ConfigTable[ID].BaseAddress;
    ptr[1] = 0;
    ptr[0] = 1;
    ptr[0] = 0;
}

