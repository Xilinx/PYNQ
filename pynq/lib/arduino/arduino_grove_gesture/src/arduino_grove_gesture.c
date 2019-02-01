/*
 * arduino_gesture.c
 *
 *  Created on: 2018/11/28
 *      Author: cchhui
 */
#include <circular_buffer.h>
#include <timer.h>
#include "grove_gesture.h"

//MailBox command
#define CONFIG_IOP_SWITCH		0x1
#define GET_GESTURE				0x3
#define SET_SPEED				0x5
#define RESET					0xF

i2c device;

int main()
{
	int cmd,gesture;
	//Initialization
	device = i2c_open_device(0);
	GestureInit();

	//Run Application
	while(1)
	{
		while((MAILBOX_CMD_ADDR & 0x01)==0);
		cmd = MAILBOX_CMD_ADDR;

		switch(cmd){
		case CONFIG_IOP_SWITCH:
		// use dedicated I2C - no operation needed
			GestureInit();
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case GET_GESTURE:
			gesture = GestureRead();
			MAILBOX_DATA(0) = (unsigned)gesture;
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case SET_SPEED:
			paj7620SelectBank(BANK1);  //gesture flag reg in Bank1
			if (MAILBOX_DATA(0) == 0x10)
				paj7620WriteReg(0x65, 0xB7); // far mode 120 fps
			else if (MAILBOX_DATA(0) == 0x30)
				paj7620WriteReg(0x65, 0x12);  // near mode 240 fps
			paj7620SelectBank(BANK0);  //gesture flag reg in Bank0
			MAILBOX_CMD_ADDR = 0x0;
			break;
		case RESET:
			GestureInit();
			MAILBOX_CMD_ADDR = 0x0;
			break;
		default:
			MAILBOX_CMD_ADDR = 0x0;
			break;
		}
	}
	return 0;
}
