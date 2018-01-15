#include <ap_fixed.h>
#include <ap_int.h>
#include <cassert>
#include <iostream>

typedef ap_uint<8> pixel_type;
typedef ap_int<8> pixel_type_s;

struct narrow_stream {
	ap_uint<32> data;
	ap_uint<1> user;
	ap_uint<1> last;
};

struct wide_stream {
	ap_uint<32> data;
	ap_uint<1> user;
	ap_uint<1> last;
};

void pixel_pack(narrow_stream* in_stream, wide_stream* out_stream, int mode, ap_uint<8> alpha);

narrow_stream input_data[24];
wide_stream output_data[24];

void reset_data() {
	for (int i = 0; i < 24; ++i) {
		output_data[i].data = 0;
		output_data[i].last = 0;
		output_data[i].user = 0;
	}
}

int main() {
	for (int i = 0; i < 24; ++i) {
		input_data[i].data.range(7,0) = 3 * i;
		input_data[i].data.range(15,8) = 3 * i + 1;
		input_data[i].data.range(23,16) = 3 * i + 2;
	}
	input_data[0].user = 1;
	input_data[23].last = 1;

	reset_data();
	pixel_pack(input_data, output_data, 0, 0);
	for (int i = 0; i < 18; ++i) {
		assert(output_data[i].user == (i == 0? 1: 0));
		assert(output_data[i].last == (i == 17? 1: 0));
		assert(output_data[i].data.range(7,0) == i*4);
		assert(output_data[i].data.range(15,8) == i*4 + 1);
		assert(output_data[i].data.range(23,16) == i*4 + 2);
		assert(output_data[i].data.range(31,24) == i*4 + 3);
	}

	reset_data();
	pixel_pack(input_data, output_data, 1, 50);
	for (int i = 0; i < 24; ++i) {
		assert(output_data[i].user == (i == 0? 1: 0));
		assert(output_data[i].last == (i == 23? 1: 0));
		assert(output_data[i].data.range(7,0) == i*3);
		assert(output_data[i].data.range(15,8) == i*3 + 1);
		assert(output_data[i].data.range(23,16) == i*3 + 2);
		assert(output_data[i].data.range(31,24) == 50);
	}

	reset_data();
	pixel_pack(input_data, output_data, 2, 0);
	for (int i = 0; i < 6; ++i) {
		assert(output_data[i].user == (i == 0? 1: 0));
		assert(output_data[i].last == (i == 5? 1: 0));
		assert(output_data[i].data.range(7,0) == i*12);
		assert(output_data[i].data.range(15,8) == i*12 + 3);
		assert(output_data[i].data.range(23,16) == i*12 + 6);
		assert(output_data[i].data.range(31,24) == i*12 + 9);
	}
}
