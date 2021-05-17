// Copyright (C) 2021 Xilinx, Inc
//
// SPDX-License-Identifier: BSD-3-Clause

#include "pixel_pack.hpp"
#include <cassert>
#include <iostream>

narrow_stream input_data;
wide_stream output_data;

void fill_stream(){
	for (int i = 0; i < 24; ++i) {
		narrow_pixel in_pixel;
		in_pixel.user = (i==0)? 1 : 0;
		in_pixel.last = (i==23)? 1 : 0;

		in_pixel.data(7,0) = 3 * i;
		in_pixel.data(15,8) = 3 * i + 1;
		in_pixel.data(23,16) = 3 * i + 2;
		input_data.write(in_pixel);
	}
}

int main() {

	fill_stream();
	while (!input_data.empty())
		pixel_pack(input_data, output_data, V_24, 0);

	for (int i = 0; i < 18; ++i) {
		wide_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 17? 1: 0));
		assert(out_pixel.data(7,0) == i*4);
		assert(out_pixel.data(15,8) == i*4 + 1);
		assert(out_pixel.data(23,16) == i*4 + 2);
		assert(out_pixel.data(31,24) == i*4 + 3);
	}

	fill_stream();
	while (!input_data.empty())
		pixel_pack(input_data, output_data, V_32, 50);

	for (int i = 0; i < 24; ++i) {
		wide_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 23? 1: 0));
		assert(out_pixel.data(7,0) == i*3);
		assert(out_pixel.data(15,8) == i*3 + 1);
		assert(out_pixel.data(23,16) == i*3 + 2);
		assert(out_pixel.data(31,24) == 50);
	}


	fill_stream();
	while (!input_data.empty())
		pixel_pack(input_data, output_data, V_8, 0);

	for (int i = 0; i < 6; ++i) {
		wide_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 5? 1: 0));
		assert(out_pixel.data(7,0) == i*12);
		assert(out_pixel.data(15,8) == i*12 + 3);
		assert(out_pixel.data(23,16) == i*12 + 6);
		assert(out_pixel.data(31,24) == i*12 + 9);
	}

	fill_stream();
	while (!input_data.empty())
		pixel_pack(input_data, output_data, V_16, 0);
	
	for (int i = 0; i < 12; ++i) {
		wide_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 11? 1: 0));
		assert(out_pixel.data(7,0) == i*6);
		assert(out_pixel.data(15,8) == i*6 + 1);
		assert(out_pixel.data(23,16) == i*6 + 3);
		assert(out_pixel.data(31,24) == i*6 + 4);
	}

	fill_stream();
	while (!input_data.empty())
		pixel_pack(input_data, output_data, V_16C, 0);
	
	for (int i = 0; i < 12; ++i) {
		wide_pixel out_pixel = output_data.read();
		assert(out_pixel.user == (i == 0? 1: 0));
		assert(out_pixel.last == (i == 11? 1: 0));
		assert(out_pixel.data(7,0) == i*6);
		assert(out_pixel.data(15,8) == i*6 + 2);
		assert(out_pixel.data(23,16) == i*6 + 3);
		assert(out_pixel.data(31,24) == i*6 + 3);
	}

	return 0;
}
