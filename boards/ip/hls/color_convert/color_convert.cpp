// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "color_convert.hpp"

void color_convert(video_stream& stream_in_24, video_stream& stream_out_24,
                   coeffs c1, coeffs c2, coeffs c3, coeffs bias) {
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE s_axilite port=c1
#pragma HLS INTERFACE s_axilite port=c2
#pragma HLS INTERFACE s_axilite port=c3
#pragma HLS INTERFACE s_axilite port=bias
#pragma HLS DISAGGREGATE variable=c1
#pragma HLS DISAGGREGATE variable=c2
#pragma HLS DISAGGREGATE variable=c3
#pragma HLS DISAGGREGATE variable=bias
#pragma HLS INTERFACE axis port=stream_in_24 register
#pragma HLS INTERFACE axis port=stream_out_24 register

#pragma HLS pipeline II=1

	pixel curr_pixel;
	stream_in_24.read(curr_pixel);
	auto v = channels(curr_pixel.data);

	comp_type in1, in2, in3, out1, out2, out3;
	in1.range() = v.p1;
	in2.range() = v.p2;
	in3.range() = v.p3;

	out1 = in1 * c1.c1 + in2 * c1.c2 + in3 * c1.c3 + bias.c1;
	out2 = in1 * c2.c1 + in2 * c2.c2 + in3 * c2.c3 + bias.c2;
	out3 = in1 * c3.c1 + in2 * c3.c2 + in3 * c3.c3 + bias.c3;

	curr_pixel.data = (out3.range(), out2.range(), out1.range());

	stream_out_24.write(curr_pixel);

}

