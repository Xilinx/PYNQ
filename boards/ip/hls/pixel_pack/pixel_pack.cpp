#include <ap_fixed.h>
#include <ap_int.h>


typedef ap_uint<8> pixel_type;
typedef ap_int<8> pixel_type_s;

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

void pixel_pack(narrow_stream* in_stream, wide_stream* out_stream, int mode, ap_uint<8> alpha) {
#pragma HLS INTERFACE ap_ctrl_none port=return
//#pragma HLS INTERFACE s_axilite port=return
#pragma HLS CLOCK domain=default
#pragma HLS INTERFACE s_axilite register port=mode clock=control
#pragma HLS INTERFACE s_axilite register port=alpha clock=control
#pragma HLS INTERFACE axis depth=24 port=in_stream
#pragma HLS INTERFACE axis depth=24 port=out_stream

	bool last = false;
	switch (mode) {
	case V_24:
		while (!last) {
#pragma HLS pipeline II=4
			ap_uint<96> buffer;
			ap_uint<4> has_last;
			ap_uint<4> has_user;
			for (int j = 0; j < 4; ++j) {
				if (!last) {
					buffer.range(j*24 + 23, j*24) = in_stream->data;
					has_user[j] = in_stream->user;
					has_last[j] = in_stream->last;
					last = in_stream->last;
					++in_stream;
				}
			}
			for (int i = 0; i < 3; ++i) {
				out_stream->data = buffer.range(i*32 + 31, i*32);
				out_stream->user = has_user[i];
				out_stream->last = has_last[i+1];
				++out_stream;
			}

		}
		break;
	case V_32:
		while (!last) {
#pragma HLS pipeline II=1
			ap_uint<32> data;
			data.range(23, 0) = in_stream->data;
			data.range(31, 24) = alpha;
			out_stream->data = data;
			out_stream->last = in_stream->last;
			out_stream->user = in_stream->user;
			last = in_stream->last;
			++out_stream;
			++in_stream;
		}
		break;
	case V_8:
		while (!last) {
#pragma HLS pipeline II=4
			bool user = false;
			ap_uint<32> data;
			for (int i = 0; i < 4; ++i) {
				if (!last) {
					user |= in_stream->user;
					last = in_stream->last;
					data.range(i*8 + 7, i * 8) = in_stream->data.range(7,0);
					++in_stream;
				}
			}
			out_stream->user = user;
			out_stream->last = last;
			out_stream->data = data;
			++out_stream;
		}
		break;
	case V_16:
		while (!last) {
#pragma HLS pipeline II=2
			bool user = false;
			ap_uint<32> data;
			for (int i = 0; i < 2; ++i) {
				user |= in_stream->user;
				last = in_stream->last;
				data.range(i*16 + 15, i*16) = in_stream->data.range(16,0);
				++in_stream;
			}
			out_stream->user = user;
			out_stream->last = last;
			out_stream->data = data;
			++out_stream;
		}
		break;
	case V_16C:
		while (!last) {
#pragma HLS pipeline II=2
			bool user = false;
			ap_uint<48> data;
			for (int i = 0; i < 2; ++i) {
				user |= in_stream->user;
				last = in_stream->last;
				data.range(i*24 + 23, i*24) = in_stream->data;
				++in_stream;
			}
			ap_uint<32> out_data;
			ap_uint<9> out_c1 = ap_uint<9>(data.range(15,8)) + ap_uint<9>(data.range(39,32));
			ap_uint<9> out_c2 = ap_uint<9>(data.range(23,16)) + ap_uint<9>(data.range(47,40));
			out_data.range(7,0) = data.range(7,0);
			out_data.range(15,8) = out_c1.range(8,1);
			out_data.range(23,16) = data.range(31,24);
			out_data.range(31,24) = out_c2.range(8,1);
			out_stream->user = user;
			out_stream->last = last;
			out_stream->data = out_data;
			++out_stream;
		}
		break;
	}
}
