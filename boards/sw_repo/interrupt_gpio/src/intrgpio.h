#ifndef INTRGPIO_H_
#define INTRGPIO_H_
#ifdef __cplusplus 
extern "C" {
#endif
#pragma once

typedef struct {
	int DeviceID;
	unsigned int BaseAddress;
} IntrGpio_Config;

void IntrGpio_RaiseInterrupt(int ID);

#ifdef __cplusplus
}
#endif
#endif