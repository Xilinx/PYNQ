/*
 * IOP code (MicroBlaze) for grove_buzzer
 * Grove Buzzer is write only, and has simple one-bit GPIO interface
 * grove_buzzer.c
 *
 *  Created on: Apr 13, 2016
 *  Author: parimalp
 */

/*
 * http://www.seeedstudio.com/wiki/Grove_-_Buzzer
 */
 
#include "xparameters.h"
#include "pmod.h"
#include "xgpio.h"

// Passed parameters in MAILBOX_WRITE_CMD
// bits 31:16 => period in us
// bits 15:1 => number of times to generate
// bit 0 => 0=tone generation, 1=melody demo

/************************** Variable Definitions *****************************/
#define SPEAKER_CHANNEL 1
XGpio pb_speaker; 			// The driver instance for GPIO Devices

void generateTone(int PeriodInUS) {	// PeriodInUS is in us delay
	XGpio_DiscreteWrite(&pb_speaker, SPEAKER_CHANNEL, 1); // turn-ON speaker
	delay_us(PeriodInUS>>1);
	XGpio_DiscreteWrite(&pb_speaker, SPEAKER_CHANNEL, 0); // turn-OFF speaker
	delay_us(PeriodInUS>>1);
}

void playTone(int tone, int duration) {	// tone is in us delay
	long i;
	for (i = 0; i < duration * 1000L; i += tone * 2) {
		generateTone(tone*2);
	}
}

/* play note */
void playNote(char note, int duration) {

	char names[] = { 'c', 'd', 'e', 'f', 'g', 'a', 'b', 'C', 'D' };
	int tones[] = { 1915, 1700, 1519, 1432, 1275, 1136, 1014, 956, 1702 };
	int i;

	// play the tone corresponding to the note name
	for (i = 0; i < 8; i++) {
		if (names[i] == note) {
		  playTone(tones[i], duration);
		}
	}
}

void melody_demo(void) {
	int length = 15;         /* the number of notes */
	char notes[] = "ccggaagffeeddc ";
	int beats[] = { 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 4 };
	int tempo = 300;
	int i;

	for(i = 0; i < length; i++) {
		if(notes[i] == ' ') {
			delay_ms(beats[i] * tempo);
		} else {
			playNote(notes[i], beats[i] * tempo);
		}
		delay_ms(tempo / 2);    /* delay between notes */
	}
}

int main(void) {
    int i=0;
	int PeriodInUS = 0x55;
	int numberoftimes = 10;
	u32 cmd;

    //	Configuring PMOD IO Switch to connect GPIO to pmod
	// bit-0 will be controlled by the software to drive the speaker
	configureSwitch(GPIO_0, GPIO_1, GPIO_2, GPIO_3, GPIO_4, GPIO_5, GPIO_6, GPIO_7);	// Buzzer is connected to bit[0] of the Channel 1 of AXI GPIO instance
	XGpio_Initialize(&pb_speaker, XPAR_GPIO_0_DEVICE_ID);
	XGpio_SetDataDirection(&pb_speaker, SPEAKER_CHANNEL, 0x0);
	XGpio_DiscreteWrite(&pb_speaker, 1, 0);	// initially keep it OFF

	pmod_init();
	while(1){
		while(MAILBOX_CMD_ADDR==0); // wait for bit[0] to become 1
		cmd = MAILBOX_CMD_ADDR;
		if(cmd & 0x1)	// check LSB
			melody_demo();
		else {
			PeriodInUS = (cmd >> 16) & 0x0ffff; // period in us
			numberoftimes = (cmd >> 1) & 0x07fff; // number of times
			for(i=0; i<numberoftimes; i++)
				generateTone(PeriodInUS);
		}
		MAILBOX_CMD_ADDR = 0x0;
	}
    return 0;

}


