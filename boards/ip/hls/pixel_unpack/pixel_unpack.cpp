#include <ap_fixed.h>
#include <ap_int.h>


struct narrow_stream {

	ap_uint<24> data;

	ap_uint<1> user;
	ap_uint<1> last;
};

struct wide_stream {
	ap_uint<32> data;
	ap_uint<1> user;
	ap_uint<1> last;
};

#define V_24 0
#define V_32 1
#define V_8 2
#define V_16 3
#define V_16C 4

void pixel_unpack(wide_stream* stream_in_32, narrow_stream* stream_out_24, 
                  int mode) {
#pragma HLS INTERFACE ap_ctrl_none port=return
// Following pragma should be used when simulating
//#pragma HLS INTERFACE s_axilite port=return
#pragma HLS CLOCK domain=default
#pragma HLS INTERFACE s_axilite register port=mode clock=control
#pragma HLS INTERFACE axis depth=24 port=stream_in_32
#pragma HLS INTERFACE axis depth=96 port=stream_out_24

	bool last = false;
	switch (mode) {
	case V_24:
		while (!last) {
#pragma HLS pipeline II=4
			ap_uint<96> buffer;
			ap_uint<1> has_last = 0;
			ap_uint<1> has_user = 0;
			for (int j = 0; j < 3; ++j) {
				buffer.range(j*32 + 31, j*32) = stream_in_32->data;
				has_user |= stream_in_32->user;
				last |= stream_in_32->last;
				++stream_in_32;
			}
			for (int i = 0; i < 4; ++i) {
				stream_out_24->data = buffer.range(i*24 + 23, i*24);
				stream_out_24->user = i == 0? has_user : ap_uint<1>(0);
				stream_out_24->last = i == 3? last : 0;
				++stream_out_24;
			}

		}
		break;
	case V_32:
		while (!last) {
#pragma HLS pipeline II=1

			stream_out_24->data = stream_in_32->data.range(23,0);
			stream_out_24->last = stream_in_32->last;
			stream_out_24->user = stream_in_32->user;
			last = stream_in_32->last;
			++stream_out_24;
			++stream_in_32;
		}
		break;
	case V_8:
		while (!last) {
#pragma HLS pipeline II=4
			ap_uint<32> data = stream_in_32->data;
			last = stream_in_32->last;
			ap_uint<1> user = stream_in_32->user;
			++stream_in_32;
			for (int i = 0; i < 4; ++i) {
				ap_uint<24> out_data = 0;
				out_data.range(7,0) = data.range(i*8 + 7, i*8);
				stream_out_24->data = out_data;
				stream_out_24->last = i == 3? last: 0;
				stream_out_24->user = i == 0? user: ap_uint<1>(0);
				++stream_out_24;
			}
		}
		break;
	case V_16:
		while (!last) {
#pragma HLS pipeline II=2
			ap_uint<32> data = stream_in_32->data;
			last = stream_in_32->last;
			ap_uint<1> user = stream_in_32->user;
			++stream_in_32;
			for (int i = 0; i < 2; ++i) {
				ap_uint<24> out_data = 0;
				out_data.range(15,0) = data.range(i*16 + 15, i*16);
				stream_out_24->data = out_data;
				stream_out_24->last = i == 1? last: 0;
				stream_out_24->user = i == 0? user: ap_uint<1>(0);
				++stream_out_24;
			}
		}
		break;
	case V_16C:
		while (!last) {
#pragma HLS pipeline II=2
			ap_uint<32> data = stream_in_32->data;
			last = stream_in_32->last;
			ap_uint<1> user = stream_in_32->user;
			++stream_in_32;
			for (int i = 0; i < 2; ++i) {
				ap_uint<24> out_data = 0;
				out_data.range(7,0) = data.range(i*16 + 7, i*16);
				out_data.range(15,8) = data.range(15,8);
				out_data.range(23,16) = data.range(31,24);
				stream_out_24->data = out_data;
				stream_out_24->last = i == 1? last: 0;
				stream_out_24->user = i == 0? user: ap_uint<1>(0);
				++stream_out_24;
			}
		}
		break;
	}
}
