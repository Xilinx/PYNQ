#include <ap_fixed.h>
#include <ap_int.h>


typedef ap_uint<8> pixel_type;
typedef ap_int<8> pixel_type_s;

struct narrow_stream {

	ap_uint<48> data;

	ap_uint<1> user;
	ap_uint<1> last;
};

struct wide_stream {
	ap_uint<64> data;
	ap_uint<1> user;
	ap_uint<1> last;
};

#define V_24 0
#define V_32 1
#define V_8 2
#define V_16 3
#define V_16C 4

void pixel_pack_2(narrow_stream* stream_in_48, wide_stream* stream_out_64,
                int mode, ap_uint<8> alpha) {
#pragma HLS INTERFACE ap_ctrl_none port=return
//#pragma HLS INTERFACE s_axilite port=return
#pragma HLS CLOCK domain=default
#pragma HLS INTERFACE s_axilite register port=mode clock=control
#pragma HLS INTERFACE s_axilite register port=alpha clock=control
#pragma HLS INTERFACE axis depth=24 port=stream_in_48 register
#pragma HLS INTERFACE axis depth=24 port=stream_out_64 register

	bool last = false;
	bool delayed_last = false;
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
					buffer.range(j*48 + 47, j*48) = stream_in_48->data;
					has_user[j] = stream_in_48->user;
					has_last[j] = stream_in_48->last;
					last = stream_in_48->last;
					++stream_in_48;
				}
			}
			if (!delayed_last) {
				for (int i = 0; i < 3; ++i) {
					stream_out_64->data = buffer.range(i*64 + 63, i*64);
					stream_out_64->user = has_user[i];
					stream_out_64->last = has_last[i+1];
					++stream_out_64;
				}
			}
		}
		break;
	case V_32:
		while (!last) {
#pragma HLS pipeline II=1
			ap_uint<64> data;
			data.range(23, 0) = stream_in_48->data.range(23,0);
			data.range(31, 24) = alpha;
			data.range(55, 32) = stream_in_48->data.range(47, 24);
			data.range(63, 56) = alpha;
			stream_out_64->data = data;
			stream_out_64->last = stream_in_48->last;
			stream_out_64->user = stream_in_48->user;
			last = stream_in_48->last;
			++stream_out_64;
			++stream_in_48;
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
					user |= stream_in_48->user;
					last = stream_in_48->last;
					data.range(i*16 + 7, i * 16) = stream_in_48->data.range(7,0);
					data.range(i*16 + 15, i * 16 + 8) = stream_in_48->data.range(31,24);
					++stream_in_48;
				}
			}
			if (!delayed_last) {
				stream_out_64->user = user;
				stream_out_64->last = last;
				stream_out_64->data = data;
				++stream_out_64;
			}
		}
		break;
	case V_16:
		while (!last) {
#pragma HLS pipeline II=2
			bool user = false;
			ap_uint<64> data;
			for (int i = 0; i < 2; ++i) {
				user |= stream_in_48->user;
				last = stream_in_48->last;
				data.range(i*32 + 15, i*32) = stream_in_48->data.range(16,0);
				data.range(i*32 + 31, i*32 + 16) = stream_in_48->data.range(39,24);
				++stream_in_48;
			}
			stream_out_64->user = user;
			stream_out_64->last = last;
			stream_out_64->data = data;
			++stream_out_64;
		}
		break;
/*	case V_16C:
		while (!last) {
#pragma HLS pipeline II=2
			bool user = false;
			ap_uint<48> data;
			for (int i = 0; i < 2; ++i) {
				user |= stream_in_24->user;
				last = stream_in_24->last;
				data.range(i*24 + 23, i*24) = stream_in_24->data;
				++stream_in_24;
			}
			ap_uint<32> out_data;
			ap_uint<9> out_c1 = \
                ap_uint<9>(data.range(15,8)) + ap_uint<9>(data.range(39,32));
			ap_uint<9> out_c2 = \
                ap_uint<9>(data.range(23,16)) + ap_uint<9>(data.range(47,40));
			out_data.range(7,0) = data.range(7,0);
			out_data.range(15,8) = out_c1.range(8,1);
			out_data.range(23,16) = data.range(31,24);
			out_data.range(31,24) = out_c2.range(8,1);
			stream_out_32->user = user;
			stream_out_32->last = last;
			stream_out_32->data = out_data;
			++stream_out_32;
		}
		break;*/
	}
}
