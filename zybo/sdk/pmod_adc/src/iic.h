#include "xil_types.h"
#include "xparameters.h"

void delay_ms(u32 ms_count);
u32 AD7991_iic_read(u32 sel); // , u32 display);
void AD7991_iic_write(u32 sel, u8 data);
