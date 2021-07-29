// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "ap_axi_sdata.h"

#define STREAM_WIDTH 64

typedef ap_axis<STREAM_WIDTH,1,1,1> word;
typedef hls::stream<word> axis;

/// frame based design
void trace_cntrl_64(axis& trace_64, 
                    axis& capture_64, 
                    ap_int<STREAM_WIDTH> trigger, int length) {
#pragma HLS INTERFACE axis depth=50 port=trace_64
#pragma HLS INTERFACE axis depth=50 port=capture_64
#pragma HLS INTERFACE s_axilite port=trigger bundle=trace_cntrl
#pragma HLS INTERFACE s_axilite port=length bundle=trace_cntrl
#pragma HLS INTERFACE s_axilite port=return bundle=trace_cntrl
int match=0;
int i;
int samples=0;
word trace_temp;

	match = false;
	for ( i = 0 ; i<length ;i++) {
	#pragma HLS pipeline // goal II=1
		trace_64.read(trace_temp);
		match = match || ((trigger.to_int() & (trace_temp.data).to_int()) == \
        trigger.to_int());

		if (match==true)  {
		  trace_temp.last=(samples==length-1);
		  capture_64.write(trace_temp);
		  samples++;
		}
		else
			i--;
	}
}
