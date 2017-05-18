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

void pixel_unpack(wide_stream* in_stream, narrow_stream* out_stream, int mode);

wide_stream input_data[24];
narrow_stream output_data[96];

void reset_data() {
	for (int i = 0; i < 72; ++i) {
		output_data[i].data = 0;
		output_data[i].last = 0;
		output_data[i].user = 0;
	}
}

int main() {
	for (int i = 0; i < 24; ++i) {
		input_data[i].data.range(7,0) = 4 * i;
		input_data[i].data.range(15,8) = 4 * i + 1;
		input_data[i].data.range(23,16) = 4 * i + 2;
		input_data[i].data.range(31,24) = 4 * i + 3;
	}
	input_data[0].user = 1;
	input_data[23].last = 1;

	reset_data();
	pixel_unpack(input_data, output_data, 0);
	for (int i = 0; i < 32; ++i) {
		assert(output_data[i].user == (i == 0? 1: 0));
		assert(output_data[i].last == (i == 31? 1: 0));
		assert(output_data[i].data.range(7,0) == i*3);
		assert(output_data[i].data.range(15,8) == i*3 + 1);
		assert(output_data[i].data.range(23,16) == i*3 + 2);
	}

	reset_data();
	pixel_unpack(input_data, output_data, 1);
	for (int i = 0; i < 24; ++i) {
		assert(output_data[i].user == (i == 0? 1: 0));
		assert(output_data[i].last == (i == 23? 1: 0));
		assert(output_data[i].data.range(7,0) == i*4);
		assert(output_data[i].data.range(15,8) == i*4 + 1);
		assert(output_data[i].data.range(23,16) == i*4 + 2);
	}

	reset_data();
	pixel_unpack(input_data, output_data, 2);
	for (int i = 0; i < 96; ++i) {
		assert(output_data[i].user == (i == 0? 1: 0));
		assert(output_data[i].last == (i == 95? 1: 0));
		assert(output_data[i].data.range(7,0) == i);
		assert(output_data[i].data.range(23,8) == 0);
	}
}
