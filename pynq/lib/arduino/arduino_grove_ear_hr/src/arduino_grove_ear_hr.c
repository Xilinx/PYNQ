/******************************************************************************
 *  Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
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
 * @file arduino_grove_ear_hr.c
 * IOP code (MicroBlaze) for grove ear-clip heart rate sensor.
 * The sensor has to be connected to an arduino interface 
 * via a shield socket.
 * http://wiki.seeed.cc/Grove-Ear-clip_Heart_Rate_Sensor/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a mr  07/05/16 release
 * 1.00b gn  10/25/16 support arduino shield
 *
 * </pre>
 *
 *****************************************************************************/

#include "arduino.h"

// Mailbox commands
// bit 1 always needs to be sets
#define CONFIG_IOP_SWITCH      0x1

// GPIO offsets
#define GPIO_TRI_OFFSET        0x4

// parameters
#define CORRECTION_FACTOR      1.46
#define SAMPLING_SLEEP_MS      40
#define MIN_HB_TIME_DIFF_MS    200*CORRECTION_FACTOR
#define MAX_HB_TIME_DIFF_MS    2500*CORRECTION_FACTOR

u8 getPinValue(u8 pin)
{
    return (Xil_In8(XPAR_GPIO_0_BASEADDR) >> pin) & 0x1;
}

int main(void)
{
    u32 cmd;
    u8 numBeats = 0;
    u8 oldInter = 0;
    u8 inter = 0;
    u8 initialized = 0; // whether the sensor has been initialized
    u8 signalPin;
    u32 time;

    arduino_init(0,0,0,0);
    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                          A_GPIO, A_SDA, A_SCL,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO);

    // Run application
    while(1)
    {
        // check if configuration is required
        cmd = MAILBOX_CMD_ADDR;
        if(cmd == CONFIG_IOP_SWITCH) {
            // read signal pin
            signalPin = MAILBOX_DATA(0);

            // set pin configuration
            config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                                  A_GPIO, A_SDA, A_SCL,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO);

            // configure GPIO for read
            Xil_Out8(XPAR_GPIO_0_BASEADDR + GPIO_TRI_OFFSET, 0xff);

            // initialize mailbox data
            MAILBOX_DATA(1) = 0;
            MAILBOX_DATA(2) = 0;
            MAILBOX_DATA(3) = 0;
            MAILBOX_DATA(4) = 0;
            MAILBOX_DATA(5) = 0;


            inter = oldInter = getPinValue(signalPin);
            time = MAX_HB_TIME_DIFF_MS;
            numBeats = 0;

            initialized = 1;
            MAILBOX_CMD_ADDR = 0;
        }

        if(initialized)
        {
            delay_ms(SAMPLING_SLEEP_MS);
            time = time + SAMPLING_SLEEP_MS;

            if(time > MIN_HB_TIME_DIFF_MS) {

                oldInter = inter;
                inter = getPinValue(signalPin);

                if(!oldInter && inter) {
                    // interrupt detected on raising transition
                    numBeats++;
                    MAILBOX_DATA(2 + numBeats%4) = time/CORRECTION_FACTOR;
                    MAILBOX_DATA(1) = numBeats;
                    time = 0;
                }
            }
        }
    }
    return 0;
}

