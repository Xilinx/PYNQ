#include <ap_fixed.h>
#include <ap_int.h>


typedef ap_uint<8> pixel_type;
typedef ap_int<8> pixel_type_s;
typedef ap_ufixed<8,0, AP_RND, AP_SAT> comp_type;
typedef ap_fixed<10,2, AP_RND, AP_SAT> coeff_type;
struct video_stream {
	struct {
		pixel_type p1;
		pixel_type p2;
		pixel_type p3;
		pixel_type p4;
		pixel_type p5;
		pixel_type p6;
	} data;
	ap_uint<1> user;
	ap_uint<1> last;
};

struct coeffs {
	coeff_type c1;
	coeff_type c2;
	coeff_type c3;
};


void color_convert_2(video_stream* stream_in_48, video_stream* stream_out_48,
                   coeffs c1, coeffs c2, coeffs c3, coeffs bias) {
#pragma HLS CLOCK domain=default
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE s_axilite register port=c1 clock=control
#pragma HLS INTERFACE s_axilite register port=c2 clock=control
#pragma HLS INTERFACE s_axilite register port=c3 clock=control
#pragma HLS INTERFACE s_axilite register port=bias clock=control
#pragma HLS INTERFACE axis port=stream_in_48 register
#pragma HLS INTERFACE axis port=stream_out_48 register

#pragma HLS pipeline II=1

	stream_out_48->user = stream_in_48->user;
	stream_out_48->last = stream_in_48->last;
	comp_type in1, in2, in3, out1, out2, out3;
	comp_type in4, in5, in6, out4, out5, out6;
	in1.range() = stream_in_48->data.p1;
	in2.range() = stream_in_48->data.p2;
	in3.range() = stream_in_48->data.p3;
	in4.range() = stream_in_48->data.p4;
	in5.range() = stream_in_48->data.p5;
	in6.range() = stream_in_48->data.p6;

	out1 = in1 * c1.c1 + in2 * c1.c2 + in3 * c1.c3 + bias.c1;
	out2 = in1 * c2.c1 + in2 * c2.c2 + in3 * c2.c3 + bias.c2;
	out3 = in1 * c3.c1 + in2 * c3.c2 + in3 * c3.c3 + bias.c3;
	out4 = in4 * c1.c1 + in5 * c1.c2 + in6 * c1.c3 + bias.c1;
	out5 = in4 * c2.c1 + in5 * c2.c2 + in6 * c2.c3 + bias.c2;
	out6 = in4 * c3.c1 + in5 * c3.c2 + in6 * c3.c3 + bias.c3;

	stream_out_48->data.p1 = out1.range();
	stream_out_48->data.p2 = out2.range();
	stream_out_48->data.p3 = out3.range();
	stream_out_48->data.p4 = out4.range();
	stream_out_48->data.p5 = out5.range();
	stream_out_48->data.p6 = out6.range();
}

