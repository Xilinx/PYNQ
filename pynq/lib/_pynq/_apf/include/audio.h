/******************************************************************************
 * @file audio.h
 *
 * This header file contains includes and function prototypes of the functions
 * defined in the 'audio.c' file.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who          Date     Changes
 * ----- ------------ -------- -----------------------------------------------
 * 1.00a Mihaita Nagy 04/06/12 First release
 *
 * </pre>
 *
 *****************************************************************************/

#ifndef AUDIO_H
#define AUDIO_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#include <stdio.h>
#include <xil_io.h>
#include <xil_printf.h>
#include <xparameters.h>

/************************** Function Prototypes ******************************/
void AudioRecord(unsigned long u32MemOffset, unsigned long u32NrSamples);
void AudioPlay(unsigned long u32MemOffset, unsigned long u32NrSamples);

#ifdef __cplusplus
}
#endif

#endif
