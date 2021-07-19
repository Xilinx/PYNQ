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
	pixel_type_s p4;
	pixel_type_s p5;
	pixel_type_s p6;
	channels() {}
	channels(ap_uint<48> pixel)
				: p1(pixel(7,0)), p2(pixel(15,8)), p3(pixel(23,16)), 
				 p4(pixel(31,24)), p5(pixel(39,32)), p6(pixel(47,40)) {}
} ;


struct coeffs {
	coeff_type c1;
	coeff_type c2;
	coeff_type c3;
};

typedef ap_axiu<48,1,0,0> pixel;
typedef hls::stream<pixel> video_stream;

void color_convert_2(video_stream& stream_in_48, video_stream& stream_out_48,
                   coeffs c1, coeffs c2, coeffs c3, coeffs bias);