// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "pixel_unpack.hpp"

void pixel_unpack_2(wide_stream& stream_in_64, narrow_stream& stream_out_48,
                  int mode) {
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE s_axilite register port=mode
#pragma HLS INTERFACE axis depth=24 port=stream_in_64 register
#pragma HLS INTERFACE axis depth=96 port=stream_out_48 register

	bool last = false;
	wide_pixel in_pixel;	
	narrow_pixel out_pixel;
	switch (mode) {
	case V_24:
		while (!last) {
#pragma HLS pipeline II=4
			ap_uint<192> buffer;
			ap_uint<1> has_last = 0;
			ap_uint<1> has_user = 0;
			for (int j = 0; j < 3; ++j) {
				stream_in_64.read(in_pixel);
				buffer(j*64 + 63, j*64) = in_pixel.data;
				has_user |= in_pixel.user;
				last |= in_pixel.last;
			}
			for (int i = 0; i < 4; ++i) {
				out_pixel.data = buffer(i*48 + 47, i*48);
				out_pixel.user = i == 0? has_user : ap_uint<1>(0);
				out_pixel.last = i == 3? last : 0;
				stream_out_48.write(out_pixel);
			}

		}
		break;
	case V_32:
		while (!last) {
#pragma HLS pipeline II=1
			ap_uint<48> data;
			stream_in_64.read(in_pixel);
			data(23,0) = in_pixel.data(23,0);
			data(47,24) = in_pixel.data(55,32);
			out_pixel.data = data;
			out_pixel.last = in_pixel.last;
			out_pixel.user = in_pixel.user;
			last = in_pixel.last;
			stream_out_48.write(out_pixel);
		}
		break;
	case V_8:
		while (!last) {
#pragma HLS pipeline II=4
			stream_in_64.read(in_pixel);
			ap_uint<64> data = in_pixel.data;
			last = in_pixel.last;
			ap_uint<1> user = in_pixel.user;
			for (int i = 0; i < 4; ++i) {
				ap_uint<48> out_data = 0;
				out_data(7,0) = data(i*16 + 7, i*16);
				out_data(31,24) = data(i * 16 + 15, i *16 + 8);
				out_pixel.data = out_data;
				out_pixel.last = i == 3? last: 0;
				out_pixel.user = i == 0? user: ap_uint<1>(0);
				stream_out_48.write(out_pixel);
			}
		}
		break;
	case V_16:
		while (!last) {
#pragma HLS pipeline II=2
			stream_in_64.read(in_pixel);
			ap_uint<64> data = in_pixel.data;
			last = in_pixel.last;
			ap_uint<1> user = in_pixel.user;
			for (int i = 0; i < 2; ++i) {
				ap_uint<48> out_data = 0;
				out_data(15,0) = data(i*32 + 15, i*32);
				out_data(47,24) = data(i*32 + 31, i*32 + 16);
				out_pixel.data = out_data;
				out_pixel.last = i == 1? last: 0;
				out_pixel.user = i == 0? user: ap_uint<1>(0);
				stream_out_48.write(out_pixel);
			}
		}
		break;
	case V_16C:
		while (!last) {
#pragma HLS pipeline II=2
			stream_in_64.read(in_pixel);
			ap_uint<64> data = in_pixel.data;
			last = in_pixel.last;
			ap_uint<1> user = in_pixel.user;
			for (int i = 0; i < 2; ++i) {
				ap_uint<48> out_data = 0;
				out_data(15,0) = data(32*i + 15,32*i);
				out_data(23,16) = data(32*i + 31,32*i + 24);
				out_data(31,24) = data(32*i + 23,32*i + 16);
				out_data(39,32) = data(32*i + 15,32*i + 8);
				out_data(47,40) = data(32*i + 31,32*i + 24);
				out_pixel.data = out_data;
				out_pixel.last = i == 1? last: 0;
				out_pixel.user = i == 0? user: ap_uint<1>(0);
				stream_out_48.write(out_pixel);
			}				
		}
		break;
	}
}
