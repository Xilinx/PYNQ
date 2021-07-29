// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "color_convert.hpp"
#include <cassert>
#include <iostream>

int main() {
	video_stream in, out;
	pixel curr_pixel;
	curr_pixel.data(7,0) = 64;
	curr_pixel.data(15,8) = 128;
	curr_pixel.data(23,16) = 191;
	curr_pixel.data(31,24) = 32;
	curr_pixel.data(39,32) = 64;
	curr_pixel.data(47,40) = 95;
	curr_pixel.user = 1;
	curr_pixel.last = 0;
	in.write(curr_pixel);

	coeffs c1,c2,c3,bias;

	c1.c1 = 1;
	c1.c2 = 1;
	c1.c3 = 1;
	c2.c1 = 0.5;
	c2.c2 = 0.5;
	c2.c3 = 0;
	c3.c1 = 0;
	c3.c2 = 0;
	c3.c3 = 1;

	bias.c1 = 0;
	bias.c2 = 0;
	bias.c3 = 0;


	color_convert_2(in, out, c1, c2, c3, bias);
	out.read(curr_pixel);
	std::cout << curr_pixel.data(7,0)  << " " << curr_pixel.data(15,8) << " " << \
	curr_pixel.data(23,16) << " " << curr_pixel.data(31,24) << " " << \
	curr_pixel.data(39,32) << " " << curr_pixel.data(47,40) << std::endl;
	assert(curr_pixel.data(7,0) == 255);
	assert(curr_pixel.data(15,8) == 96);
	assert(curr_pixel.data(23,16) == 191);
	assert(curr_pixel.data(31,24) == 191);
	assert(curr_pixel.data(39,32) == 48);
	assert(curr_pixel.data(47,40) == 95);

	return 0;

}
