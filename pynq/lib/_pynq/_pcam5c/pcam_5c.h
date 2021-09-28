/******************************************************************************
 *  Copyright (c) 2020, Xilinx, Inc.
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

/*
 * pcam_5c.h
 *
 *  Created on: Dec 19, 2019
 *      Author: parimalp
 */

#ifndef SRC_PCAM_5C_H_
#define SRC_PCAM_5C_H_


struct config_word_t {
	uint16_t addr;
	uint8_t data;
};
//config_word_t;

struct config_word_t const cfg_advanced_awb_[] =
{
	// Enable Advanced AWB
	{0x3406 ,0x00},
	{0x5192 ,0x04},
	{0x5191 ,0xf8},
	{0x518d ,0x26},
	{0x518f ,0x42},
	{0x518e ,0x2b},
	{0x5190 ,0x42},
	{0x518b ,0xd0},
	{0x518c ,0xbd},
	{0x5187 ,0x18},
	{0x5188 ,0x18},
	{0x5189 ,0x56},
	{0x518a ,0x5c},
	{0x5186 ,0x1c},
	{0x5181 ,0x50},
	{0x5184 ,0x20},
	{0x5182 ,0x11},
	{0x5183 ,0x00},
	{0x5001 ,0x03}
};

struct config_word_t const cfg_simple_awb_[] =
{
	// Disable Advanced AWB
	{0x518d ,0x00},
	{0x518f ,0x20},
	{0x518e ,0x00},
	{0x5190 ,0x20},
	{0x518b ,0x00},
	{0x518c ,0x00},
	{0x5187 ,0x10},
	{0x5188 ,0x10},
	{0x5189 ,0x40},
	{0x518a ,0x40},
	{0x5186 ,0x10},
	{0x5181 ,0x58},
	{0x5184 ,0x25},
	{0x5182 ,0x11},

	// Enable simple AWB
	{0x3406 ,0x00},
	{0x5183 ,0x80},
	{0x5191 ,0xff},
	{0x5192 ,0x00},
	{0x5001 ,0x03}
};

struct config_word_t const cfg_disable_awb_[] =
{
	{0x5001 ,0x02}
};

struct config_word_t const cfg_720p_60fps_[] =
{//1280 x 720 binned, RAW10, MIPISCLK=280M, SCLK=56Mz, PCLK=56M
	//PLL1 configuration
	//[7:4]=0010 System clock divider /2, [3:0]=0001 Scale divider for MIPI /1
	{0x3035, 0x21},
	//[7:0]=70 PLL multiplier
	{0x3036, 0x46},
	//[4]=0 PLL root divider /1, [3:0]=5 PLL pre-divider /1.5
	{0x3037, 0x05},
	//[5:4]=01 PCLK root divider /2, [3:2]=00 SCLK2x root divider /1, [1:0]=01 SCLK root divider /2
	{0x3108, 0x11},

	//[6:4]=001 PLL charge pump, [3:0]=1010 MIPI 10-bit mode
	{0x3034, 0x1A},

	//[3:0]=0 X address start high byte
	{0x3800, (0 >> 8) & 0x0F},
	//[7:0]=0 X address start low byte
	{0x3801, 0 & 0xFF},
	//[2:0]=0 Y address start high byte
	{0x3802, (8 >> 8) & 0x07},
	//[7:0]=0 Y address start low byte
	{0x3803, 8 & 0xFF},

	//[3:0] X address end high byte
	{0x3804, (2619 >> 8) & 0x0F},
	//[7:0] X address end low byte
	{0x3805, 2619 & 0xFF},
	//[2:0] Y address end high byte
	{0x3806, (1947 >> 8) & 0x07},
	//[7:0] Y address end low byte
	{0x3807, 1947 & 0xFF},

	//[3:0]=0 timing hoffset high byte
	{0x3810, (0 >> 8) & 0x0F},
	//[7:0]=0 timing hoffset low byte
	{0x3811, 0 & 0xFF},
	//[2:0]=0 timing voffset high byte
	{0x3812, (0 >> 8) & 0x07},
	//[7:0]=0 timing voffset low byte
	{0x3813, 0 & 0xFF},

	//[3:0] Output horizontal width high byte
	{0x3808, (1280 >> 8) & 0x0F},
	//[7:0] Output horizontal width low byte
	{0x3809, 1280 & 0xFF},
	//[2:0] Output vertical height high byte
	{0x380a, (720 >> 8) & 0x7F},
	//[7:0] Output vertical height low byte
	{0x380b, 720 & 0xFF},

	//HTS line exposure time in # of pixels
	{0x380c, (1896 >> 8) & 0x1F},
	{0x380d, 1896 & 0xFF},
	//VTS frame exposure time in # lines
	{0x380e, (984 >> 8) & 0xFF},
	{0x380f, 984 & 0xFF},

	//[7:4]=0x3 horizontal odd subsample increment, [3:0]=0x1 horizontal even subsample increment
	{0x3814, 0x31},
	//[7:4]=0x3 vertical odd subsample increment, [3:0]=0x1 vertical even subsample increment
	{0x3815, 0x31},

	//[2]=0 ISP mirror, [1]=0 sensor mirror, [0]=1 horizontal binning
	{0x3821, 0x01},

	//little MIPI shit: global timing unit, period of PCLK in ns * 2(depends on # of lanes)
	{0x4837, 36}, // 1/56M*2

	//Undocumented anti-green settings
	{0x3618, 0x00}, // Removes vertical lines appearing under bright light
	{0x3612, 0x59},
	{0x3708, 0x64},
	{0x3709, 0x52},
	{0x370c, 0x03},

	//[7:4]=0x0 Formatter RAW, [3:0]=0x0 BGBG/GRGR
	{0x4300, 0x00},
	//[2:0]=0x3 Format select ISP RAW (DPC)
	{0x501f, 0x03}
};
struct config_word_t const cfg_1080p_15fps_[] =
{//1920 x 1080 @ 15 fps, RAW10, MIPISCLK=210, SCLK=42MHz, PCLK=42M
	// PLL1 configuration
	// [7:4]=0100 System clock divider /4, [3:0]=0001 Scale divider for MIPI /1
	{0x3035, 0x41},
	// [7:0]=105 PLL multiplier
	{0x3036, 0x69},
	// [4]=0 PLL root divider /1, [3:0]=5 PLL pre-divider /1.5
	{0x3037, 0x05},
	// [5:4]=01 PCLK root divider /2, [3:2]=00 SCLK2x root divider /1, [1:0]=01 SCLK root divider /2
	{0x3108, 0x11},

	// [6:4]=001 PLL charge pump, [3:0]=1010 MIPI 10-bit mode
	{0x3034, 0x1A},

	// [3:0]=0 X address start high byte
	{0x3800, (336 >> 8) & 0x0F},
	// [7:0]=0 X address start low byte
	{0x3801, 336 & 0xFF},
	// [2:0]=0 Y address start high byte
	{0x3802, (426 >> 8) & 0x07},
	// [7:0]=0 Y address start low byte
	{0x3803, 426 & 0xFF},

	// [3:0] X address end high byte
	{0x3804, (2287 >> 8) & 0x0F},
	// [7:0] X address end low byte
	{0x3805, 2287 & 0xFF},
	// [2:0] Y address end high byte
	{0x3806, (1529 >> 8) & 0x07},
	// [7:0] Y address end low byte
	{0x3807, 1529 & 0xFF},

	// [3:0]=0 timing hoffset high byte
	{0x3810, (16 >> 8) & 0x0F},
	// [7:0]=0 timing hoffset low byte
	{0x3811, 16 & 0xFF},
	// [2:0]=0 timing voffset high byte
	{0x3812, (12 >> 8) & 0x07},
	// [7:0]=0 timing voffset low byte
	{0x3813, 12 & 0xFF},

	// [3:0] Output horizontal width high byte
	{0x3808, (1920 >> 8) & 0x0F},
	// [7:0] Output horizontal width low byte
	{0x3809, 1920 & 0xFF},
	// [2:0] Output vertical height high byte
	{0x380a, (1080 >> 8) & 0x7F},
	// [7:0] Output vertical height low byte
	{0x380b, 1080 & 0xFF},

	// HTS line exposure time in # of pixels Tline=HTS/sclk
	{0x380c, (2500 >> 8) & 0x1F},
	{0x380d, 2500 & 0xFF},
	// VTS frame exposure time in # lines
	{0x380e, (1120 >> 8) & 0xFF},
	{0x380f, 1120 & 0xFF},

	// [7:4]=0x1 horizontal odd subsample increment, [3:0]=0x1 horizontal even subsample increment
	{0x3814, 0x11},
	// [7:4]=0x1 vertical odd subsample increment, [3:0]=0x1 vertical even subsample increment
	{0x3815, 0x11},

	// [2]=0 ISP mirror, [1]=0 sensor mirror, [0]=0 no horizontal binning
	{0x3821, 0x00},

	// little MIPI shit: global timing unit, period of PCLK in ns * 2(depends on # of lanes)
	{0x4837, 48}, // 1/42M*2

	// Undocumented anti-green settings
	{0x3618, 0x00}, // Removes vertical lines appearing under bright light
	{0x3612, 0x59},
	{0x3708, 0x64},
	{0x3709, 0x52},
	{0x370c, 0x03},

	// [7:4]=0x0 Formatter RAW, [3:0]=0x0 BGBG/GRGR
	{0x4300, 0x00},
	// [2:0]=0x3 Format select ISP RAW (DPC)
	{0x501f, 0x03}
};
struct config_word_t const cfg_1080p_30fps_[] =
{//1920 x 1080 @ 30fps, RAW10, MIPISCLK=420, SCLK=84MHz, PCLK=84M
	//PLL1 configuration
	//[7:4]=0010 System clock divider /2, [3:0]=0001 Scale divider for MIPI /1
	{0x3035, 0x21}, // 30fps setting
	//[7:0]=105 PLL multiplier
	{0x3036, 0x69},
	//[4]=0 PLL root divider /1, [3:0]=5 PLL pre-divider /1.5
	{0x3037, 0x05},
	//[5:4]=01 PCLK root divider /2, [3:2]=00 SCLK2x root divider /1, [1:0]=01 SCLK root divider /2
	{0x3108, 0x11},

	//[6:4]=001 PLL charge pump, [3:0]=1010 MIPI 10-bit mode
	{0x3034, 0x1A},

	//[3:0]=0 X address start high byte
	{0x3800, (336 >> 8) & 0x0F},
	//[7:0]=0 X address start low byte
	{0x3801, 336 & 0xFF},
	//[2:0]=0 Y address start high byte
	{0x3802, (426 >> 8) & 0x07},
	//[7:0]=0 Y address start low byte
	{0x3803, 426 & 0xFF},

	//[3:0] X address end high byte
	{0x3804, (2287 >> 8) & 0x0F},
	//[7:0] X address end low byte
	{0x3805, 2287 & 0xFF},
	//[2:0] Y address end high byte
	{0x3806, (1529 >> 8) & 0x07},
	//[7:0] Y address end low byte
	{0x3807, 1529 & 0xFF},

	//[3:0]=0 timing hoffset high byte
	{0x3810, (16 >> 8) & 0x0F},
	//[7:0]=0 timing hoffset low byte
	{0x3811, 16 & 0xFF},
	//[2:0]=0 timing voffset high byte
	{0x3812, (12 >> 8) & 0x07},
	//[7:0]=0 timing voffset low byte
	{0x3813, 12 & 0xFF},

	//[3:0] Output horizontal width high byte
	{0x3808, (1920 >> 8) & 0x0F},
	//[7:0] Output horizontal width low byte
	{0x3809, 1920 & 0xFF},
	//[2:0] Output vertical height high byte
	{0x380a, (1080 >> 8) & 0x7F},
	//[7:0] Output vertical height low byte
	{0x380b, 1080 & 0xFF},

	//HTS line exposure time in # of pixels Tline=HTS/sclk
	{0x380c, (2500 >> 8) & 0x1F},
	{0x380d, 2500 & 0xFF},
	//VTS frame exposure time in # lines
	{0x380e, (1120 >> 8) & 0xFF},
	{0x380f, 1120 & 0xFF},

	//[7:4]=0x1 horizontal odd subsample increment, [3:0]=0x1 horizontal even subsample increment
	{0x3814, 0x11},
	//[7:4]=0x1 vertical odd subsample increment, [3:0]=0x1 vertical even subsample increment
	{0x3815, 0x11},

	//[2]=0 ISP mirror, [1]=0 sensor mirror, [0]=0 no horizontal binning
	{0x3821, 0x00},

	//little MIPI shit: global timing unit, period of PCLK in ns * 2(depends on # of lanes)
	{0x4837, 24}, // 1/84M*2

	//Undocumented anti-green settings
	{0x3618, 0x00}, // Removes vertical lines appearing under bright light
	{0x3612, 0x59},
	{0x3708, 0x64},
	{0x3709, 0x52},
	{0x370c, 0x03},

	//[7:4]=0x0 Formatter RAW, [3:0]=0x0 BGBG/GRGR
	{0x4300, 0x00},
	//[2:0]=0x3 Format select ISP RAW (DPC)
	{0x501f, 0x03}
};

struct config_word_t const cfg_init_[] =
{
	//[7]=0 Software reset; [6]=1 Software power down; Default=0x02
	{0x3008, 0x42},
	//[1]=1 System input clock from PLL; Default read = 0x11
	{0x3103, 0x03},
	//[3:0]=0000 MD2P,MD2N,MCP,MCN input; Default=0x00
	{0x3017, 0x00},
	//[7:2]=000000 MD1P,MD1N, D3:0 input; Default=0x00
	{0x3018, 0x00},
	//[6:4]=001 PLL charge pump, [3:0]=1000 MIPI 8-bit mode
	{0x3034, 0x18},

	//              +----------------+        +------------------+         +---------------------+        +---------------------+
	//XVCLK         | PRE_DIV0       |        | Mult (4+252)     |         | Sys divider (0=16)  |        | MIPI divider (0=16) |
	//+-------+-----> 3037[3:0]=0001 +--------> 3036[7:0]=0x38   +---------> 3035[7:4]=0001      +--------> 3035[3:0]=0001      |
	//12MHz   |     | / 1            | 12MHz  | * 56             | 672MHz  | / 1                 | 672MHz | / 1                 |
	//        |     +----------------+        +------------------+         +----------+----------+        +----------+----------+
	//        |                                                                       |                              |
	//        |                                                                       |                      MIPISCLK|672MHz
	//        |                                                                       |                              |
	//        |     +----------------+        +------------------+         +----------v----------+        +----------v----------+
	//        |     | PRE_DIVSP      |        | R_DIV_SP         |         | PLL R divider       |        | MIPI PHY            | MIPI_CLK
	//        +-----> 303d[5:4]=01   +--------> 303d[2]=0 (+1)   |         | 3037[4]=1 (+1)      |        |                     +------->
	//              | / 1.5          |  8MHz  | / 1              |         | / 2                 |        | / 2                 | 336MHz
	//              +----------------+        +---------+--------+         +----------+----------+        +---------------------+
	//                                                  |                             |
	//                                                  |                             |
	//                                                  |                             |
	//              +----------------+        +---------v--------+         +----------v----------+        +---------------------+
	//              | SP divider     |        | Mult             |         | BIT div (MIPI 8/10) |        | SCLK divider        | SCLK
	//              | 303c[3:0]=0x1  +<-------+ 303b[4:0]=0x19   |         | 3034[3:0]=0x8)      +----+---> 3108[1:0]=01 (2^)   +------->
	//              | / 1            | 200MHz | * 25             |         | / 2                 |    |   | / 2                 | 84MHz
	//              +--------+-------+        +------------------+         +----------+----------+    |   +---------------------+
	//                       |                                                        |               |
	//                       |                                                        |               |
	//                       |                                                        |               |
	//              +--------v-------+                                     +----------v----------+    |   +---------------------+
	//              | R_SELD5 div    | ADCCLK                              | PCLK div            |    |   | SCLK2x divider      |
	//              | 303d[1:0]=001  +------->                             | 3108[5:4]=00 (2^)   |    +---> 3108[3:2]=00 (2^)   +------->
	//              | / 1            | 200MHz                              | / 1                 |        | / 1                 | 168MHz
	//              +----------------+                                     +----------+----------+        +---------------------+
	//                                                                                |
	//                                                                                |
	//                                                                                |
	//                                                                     +----------v----------+        +---------------------+
	//                                                                     | P divider (* #lanes)| PCLK   | Scale divider       |
	//                                                                     | 3035[3:0]=0001      +--------> 3824[4:0]           |
	//                                                                     | / 1                 | 168MHz | / 2                 |
	//                                                                     +---------------------+        +---------------------+

	//PLL1 configuration
	//[7:4]=0001 System clock divider /1, [3:0]=0001 Scale divider for MIPI /1
	{0x3035, 0x11},
	//[7:0]=56 PLL multiplier
	{0x3036, 0x38},
	//[4]=1 PLL root divider /2, [3:0]=1 PLL pre-divider /1
	{0x3037, 0x11},
	//[5:4]=00 PCLK root divider /1, [3:2]=00 SCLK2x root divider /1, [1:0]=01 SCLK root divider /2
	{0x3108, 0x01},
	//PLL2 configuration
	//[5:4]=01 PRE_DIV_SP /1.5, [2]=1 R_DIV_SP /1, [1:0]=00 DIV12_SP /1
	{0x303D, 0x10},
	//[4:0]=11001 PLL2 multiplier DIV_CNT5B = 25
	{0x303B, 0x19},

	{0x3630, 0x2e},
	{0x3631, 0x0e},
	{0x3632, 0xe2},
	{0x3633, 0x23},
	{0x3621, 0xe0},
	{0x3704, 0xa0},
	{0x3703, 0x5a},
	{0x3715, 0x78},
	{0x3717, 0x01},
	{0x370b, 0x60},
	{0x3705, 0x1a},
	{0x3905, 0x02},
	{0x3906, 0x10},
	{0x3901, 0x0a},
	{0x3731, 0x02},
	//VCM debug mode
	{0x3600, 0x37},
	{0x3601, 0x33},
	//System control register changing not recommended
	{0x302d, 0x60},
	//??
	{0x3620, 0x52},
	{0x371b, 0x20},
	//?? DVP
	{0x471c, 0x50},

	{0x3a13, 0x43},
	{0x3a18, 0x00},
	{0x3a19, 0xf8},
	{0x3635, 0x13},
	{0x3636, 0x06},
	{0x3634, 0x44},
	{0x3622, 0x01},
	{0x3c01, 0x34},
	{0x3c04, 0x28},
	{0x3c05, 0x98},
	{0x3c06, 0x00},
	{0x3c07, 0x08},
	{0x3c08, 0x00},
	{0x3c09, 0x1c},
	{0x3c0a, 0x9c},
	{0x3c0b, 0x40},

	//[7]=1 color bar enable, [3:2]=00 eight color bar
	{0x503d, 0x00},
	//[2]=1 ISP vflip, [1]=1 sensor vflip
	{0x3820, 0x46},

	//[7:5]=010 Two lane mode, [4]=0 MIPI HS TX no power down, [3]=0 MIPI LP RX no power down, [2]=1 MIPI enable, [1:0]=10 Debug mode; Default=0x58
	{0x300e, 0x45},
	//[7:5]=010 One lane mode, [4]=0 MIPI HS TX no power down, [3]=0 MIPI LP RX no power down, [2]=1 MIPI enable, [1:0]=10 Debug mode; Default=0x58
	//{0x300e, 0x25},
	//[5]=0 Clock free running, [4]=1 Send line short packet, [3]=0 Use lane1 as default, [2]=1 MIPI bus LP11 when no packet; Default=0x04
	{0x4800, 0x14},
	{0x302e, 0x08},
	//[7:4]=0x3 YUV422, [3:0]=0x0 YUYV
	//{0x4300, 0x30},
	//[7:4]=0x6 RGB565, [3:0]=0x0 {b[4:0],g[5:3],g[2:0],r[4:0]}
	{0x4300, 0x6f}, // 0x00}, // RAW10 0x6f},
	{0x501f, 0x01}, // 0x03}, // RAW10 0x01},

	{0x4713, 0x03},
	{0x4407, 0x04},
	{0x440e, 0x00},
	{0x460b, 0x35},
	//[1]=0 DVP PCLK divider manual control by 0x3824[4:0]
	{0x460c, 0x20},
	//[4:0]=1 SCALE_DIV=INT(3824[4:0]/2)
	{0x3824, 0x01},

	//MIPI timing
	//		{0x4805, 0x10}, //LPX global timing select=auto
	//		{0x4818, 0x00}, //hs_prepare + hs_zero_min ns
	//		{0x4819, 0x96},
	//		{0x482A, 0x00}, //hs_prepare + hs_zero_min UI
	//
	//		{0x4824, 0x00}, //lpx_p_min ns
	//		{0x4825, 0x32},
	//		{0x4830, 0x00}, //lpx_p_min UI
	//
	//		{0x4826, 0x00}, //hs_prepare_min ns
	//		{0x4827, 0x32},
	//		{0x4831, 0x00}, //hs_prepare_min UI

	//[7]=1 LENC correction enabled, [5]=1 RAW gamma enabled, [2]=1 Black pixel cancellation enabled, [1]=1 White pixel cancellation enabled, [0]=1 Color interpolation enabled
	{0x5000, 0x07},
	//[7]=0 Special digital effects, [5]=0 scaling, [2]=0 UV average disabled, [1]=1 Color matrix enabled, [0]=1 Auto white balance enabled
	{0x5001, 0x03}
};
//config_modes_t const modes[] =
//{
//		{ MAP_ENUM_TO_CFG(MODE_720P_1280_720_60fps, cfg_720p_60fps_) },
//		{ MAP_ENUM_TO_CFG(MODE_1080P_1920_1080_15fps, cfg_1080p_15fps_) },
//		{ MAP_ENUM_TO_CFG(MODE_1080P_1920_1080_30fps, cfg_1080p_30fps_) }
//};
//config_awb_t const awbs[] =
//{
//		{ MAP_ENUM_TO_CFG(AWB_DISABLED, cfg_disable_awb_) },
//		{ MAP_ENUM_TO_CFG(AWB_SIMPLE, cfg_simple_awb_) },
//		{ MAP_ENUM_TO_CFG(AWB_ADVANCED, cfg_advanced_awb_) }
//};

#endif /* SRC_PCAM_5C_H_ */

