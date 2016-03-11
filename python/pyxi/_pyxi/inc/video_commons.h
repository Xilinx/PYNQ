/*
 * Common macros for video
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   23 NOV 2015
 */

#define MAX_FRAME_WIDTH  1920
#define MAX_FRAME_HEIGHT 1080
#define NUM_FRAMES       3
#define MAX_FRAME        MAX_FRAME_WIDTH*MAX_FRAME_HEIGHT*NUM_FRAMES
#define STRIDE           MAX_FRAME_WIDTH*NUM_FRAMES