// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "pixel_unpack.hpp"
#include <cassert>
#include <iostream>

wide_stream input_data;
narrow_stream output_data;

void fill_stream(){
	for (int i = 0; i < 	24; ++i) {
		wide_pixel in_pixel;
		in_pixel.user = (i==0)? 1 : 0;
		in_pixel.last = (i==23)? 1 : 0;

		in_pixel.data(7,0) = 8 * i;
		in_pixel.data(15,8) = 8 * i + 1;
		in_pixel.data(23,16) = 8 * i + 2;
		in_pixel.data(31,24) = 8 * i + 3;
		in_pixel.data(39,32) = 8 * i + 4;
		in_pixel.data(47,40) = 8 * i + 5;
		in_pixel.data(55,48) = 8 * i + 6;
		in_pixel.data(63,56) = 8 * i + 7;
		input_data.write(in_pixel);
	}
}

int main() {

	fill_stream();
	while(!input_data.empty())
		pixel_unpack_2(input_data, output_data, V_24);
	for (int i = 0; i < 32; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 31? 1: 0));
		assert(out_pixel.data(7,0) == i*6);
		assert(out_pixel.data(15,8) == i*6 + 1);
		assert(out_pixel.data(23,16) == i*6 + 2);
		assert(out_pixel.data(31,24) == i*6 + 3);
		assert(out_pixel.data(39,32) == i*6 + 4);
		assert(out_pixel.data(47,40) == i*6 + 5);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack_2(input_data, output_data, V_32);
	for (int i = 0; i < 24; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 23? 1: 0));
		assert(out_pixel.data(7,0) == i*8);
		assert(out_pixel.data(15,8) == i*8 + 1);
		assert(out_pixel.data(23,16) == i*8 + 2);
		assert(out_pixel.data(31,24) == i*8 + 4);
		assert(out_pixel.data(39,32) == i*8 + 5);
		assert(out_pixel.data(47,40) == i*8 + 6);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack_2(input_data, output_data, V_8);
	for (int i = 0; i < 96; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 95? 1: 0));
		assert(out_pixel.data(7,0) == i * 2);
		assert(out_pixel.data(23,8) == 0);
		assert(out_pixel.data(31,24) == i * 2 + 1);
		assert(out_pixel.data(47,32) == 0);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack_2(input_data, output_data, V_16);
	for (int i = 0; i < 48; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 47? 1: 0));
		assert(out_pixel.data(7,0) == i*4);
		assert(out_pixel.data(15,8) == i*4 + 1);
		assert(out_pixel.data(23,16) == 0);
		assert(out_pixel.data(31,24) == i*4 + 2);
		assert(out_pixel.data(39,32) == i*4 + 3);
		assert(out_pixel.data(47,40) == 0);
	}

	fill_stream();
	while(!input_data.empty())
		pixel_unpack_2(input_data, output_data, V_16C);
	for (int i = 0; i < 48; ++i) {
		narrow_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 47? 1: 0));
		assert(out_pixel.data(7,0) == i*4);
		assert(out_pixel.data(15,8) == i*4 + 1);
		assert(out_pixel.data(23,16) == i*4 + 3);
		assert(out_pixel.data(31,24) == i*4 + 2);
		assert(out_pixel.data(39,32) == i*4 + 1);
		assert(out_pixel.data(47,40) == i*4 + 3);
	}	

	return 0;
}
