// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "pixel_pack.hpp"

void pixel_pack_2(narrow_stream& stream_in_48, wide_stream& stream_out_64,
				int mode, ap_uint<8> alpha) {
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE s_axilite register port=mode
#pragma HLS INTERFACE s_axilite register port=alpha
#pragma HLS INTERFACE axis depth=24 port=stream_in_48 register
#pragma HLS INTERFACE axis depth=24 port=stream_out_64 register

	bool last = false;
	bool delayed_last = false;
	narrow_pixel in_pixel;
	wide_pixel out_pixel;
	switch (mode) {
	case V_24:
		while (!delayed_last) {
#pragma HLS pipeline II=4
			delayed_last = last;
			ap_uint<192> buffer;
			ap_uint<4> has_last;
			ap_uint<4> has_user;
			for (int j = 0; j < 4; ++j) {
				if (!last) {
					stream_in_48.read(in_pixel);
					buffer(j*48 + 47, j*48) = in_pixel.data;
					has_user[j] = in_pixel.user;
					has_last[j] = in_pixel.last;
					last = in_pixel.last;
				}
			}
			if (!delayed_last) {
				for (int i = 0; i < 3; ++i) {
					out_pixel.data = buffer(i*64 + 63, i*64);
					out_pixel.user = has_user[i];
					out_pixel.last = has_last[i+1];
					stream_out_64.write(out_pixel);
				}
			}
		}
		break;
	case V_32:
		while (!last) {
#pragma HLS pipeline II=1
			stream_in_48.read(in_pixel);
			ap_uint<64> data;
			data(23, 0) = in_pixel.data(23,0);
			data(31, 24) = alpha;
			data(55, 32) = in_pixel.data(47, 24);
			data(63, 56) = alpha;
			out_pixel.data = data;
			out_pixel.last = in_pixel.last;
			out_pixel.user = in_pixel.user;
			last = in_pixel.last;
			stream_out_64.write(out_pixel);

		}
		break;
	case V_8:
		while (!delayed_last) {
#pragma HLS pipeline II=4
			delayed_last = last;
			bool user = false;
			ap_uint<64> data;
			for (int i = 0; i < 4; ++i) {
				if (!last) {
					stream_in_48.read(in_pixel);
					user |= in_pixel.user;
					last = in_pixel.last;
					data(i*16 + 7, i * 16) = in_pixel.data(7,0);
					data(i*16 + 15, i * 16 + 8) = in_pixel.data(31,24);
				}
			}
			if (!delayed_last) {
				out_pixel.user = user;
				out_pixel.last = last;
				out_pixel.data = data;
				stream_out_64.write(out_pixel);
			}
		}
		break;
	case V_16:
		while (!last) {
#pragma HLS pipeline II=2
			bool user = false;
			ap_uint<64> data;
			for (int i = 0; i < 2; ++i) {
				stream_in_48.read(in_pixel);
				user |= in_pixel.user;
				last = in_pixel.last;
				data(i*32 + 15, i*32) = in_pixel.data(16,0);
				data(i*32 + 31, i*32 + 16) = in_pixel.data(39,24);
			}
			out_pixel.user = user;
			out_pixel.last = last;
			out_pixel.data = data;
			stream_out_64.write(out_pixel);
		}
		break;
	case V_16C:
		while (!last) {
#pragma HLS pipeline II=2
			bool user = false;
			ap_uint<96> data;
			for (int i = 0; i < 2; ++i) {
				stream_in_48.read(in_pixel);
				user |= in_pixel.user;
				last = in_pixel.last;
				data(i*48 + 47, i*48) = in_pixel.data;
			}
			ap_uint<64> out_data;
			ap_uint<9> out_c1 = \
				ap_uint<9>(data(15,8)) + ap_uint<9>(data(39,32));
			ap_uint<9> out_c2 = \
				ap_uint<9>(data(23,16)) + ap_uint<9>(data(47,40));
			out_data(7,0) = data(7,0);
			out_data(15,8) = out_c1(8,1);
			out_data(23,16) = data(31,24);
			out_data(31,24) = out_c2(8,1);
			ap_uint<9> out_c3 = \
				ap_uint<9>(data(63,56)) + ap_uint<9>(data(87,80));
			ap_uint<9> out_c4 = \
				ap_uint<9>(data(71,64)) + ap_uint<9>(data(95,88));
			out_data(39,32) = data(55,48);
			out_data(47,40) = out_c3(8,1);
			out_data(55,48) = data(79,72);
			out_data(63,56) = out_c4(8,1);
			out_pixel.user = user;
			out_pixel.last = last;
			out_pixel.data = out_data;
			stream_out_64.write(out_pixel);
		}
		break;
	}
}
