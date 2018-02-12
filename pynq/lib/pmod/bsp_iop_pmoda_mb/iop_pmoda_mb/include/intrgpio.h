#pragma once

typedef struct {
	int DeviceID;
	unsigned int BaseAddress;
} IntrGpio_Config;

void IntrGpio_RaiseInterrupt(int ID);
