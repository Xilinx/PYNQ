// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "pixel_unpack.hpp"
#include <cassert>
#include <iostream>

wide_stream input_data;
narrow_stream output_data;

void fill_stream(){
	for (int i = 0; i < 24; ++i) {
		wide_pixel in_pixel;
		in_pixel.user = (i==0)? 1 : 0;
		in_pixel.last = (i==23)? 1 : 0;

		in_pixel.data(7,0) = 4 * i;
		in_pixel.data(15,8) = 4 * i + 1;
		in_pixel.data(23,16) = 4 * i + 2;
		in_pixel.data(31,24) = 4 * i + 3;
		
		input_data.write(in_pixel);
	}
}


int main() {

	fill_stream();
	while(!input_data.empty())
		pixel_unpack(input_data, output_data, V_24);
	for (int i = 0; i < 32; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 31? 1: 0));
		assert(out_pixel.data(7,0) == i*3);
		assert(out_pixel.data(15,8) == i*3 + 1);
		assert(out_pixel.data(23,16) == i*3 + 2);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack(input_data, output_data, V_32);
	for (int i = 0; i < 24; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 23? 1: 0));
		assert(out_pixel.data(7,0) == i*4);
		assert(out_pixel.data(15,8) == i*4 + 1);
		assert(out_pixel.data(23,16) == i*4 + 2);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack(input_data, output_data, V_8);
	for (int i = 0; i < 96; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 95? 1: 0));
		assert(out_pixel.data(7,0) == i);
		assert(out_pixel.data(23,8) == 0);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack(input_data, output_data, V_16);
	for (int i = 0; i < 48; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 47? 1: 0));
		assert(out_pixel.data(7,0) == i*2);
		assert(out_pixel.data(15,8) == i*2 + 1);
		assert(out_pixel.data(23,16) == 0);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack(input_data, output_data, V_16C);
	for (int i = 0; i < 48; ++i) {
		narrow_pixel out_pixel = output_data.read();
		std::cout << "value " << out_pixel.data(23,16) << " " << out_pixel.data(15,8) << " " << out_pixel.data(7,0) << std::endl;
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 47? 1: 0));
		assert(out_pixel.data(7,0) == i*2);
		assert(out_pixel.data(15,8) == (i/2)*4 + 1);
		assert(out_pixel.data(23,16) == (i/2)*4 + 3);
	}

	return 0;
}
