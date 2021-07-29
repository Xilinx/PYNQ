// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include <ap_fixed.h>
#include <ap_int.h>
#include "hls_stream.h"
#include <ap_axi_sdata.h>

//typedef ap_uint<8> pixel_type;
typedef ap_int<8> pixel_type_s;
typedef ap_ufixed<8,0, AP_RND, AP_SAT> comp_type;
typedef ap_fixed<10,2, AP_RND, AP_SAT> coeff_type;

struct channels {
	pixel_type_s p1;
	pixel_type_s p2;
	pixel_type_s p3;
	channels() {}
	channels(ap_uint<24> pixel)
				: p1(pixel(7,0)), p2(pixel(15,8)), p3(pixel(23,16)) {}
} ;


struct coeffs {
	coeff_type c1;
	coeff_type c2;
	coeff_type c3;
};

typedef ap_axiu<24,1,0,0> pixel;
typedef hls::stream<pixel> video_stream;

void color_convert(video_stream& stream_in_24, video_stream& stream_out_24,
                   coeffs c1, coeffs c2, coeffs c3, coeffs bias);