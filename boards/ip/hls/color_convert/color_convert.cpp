#include <ap_fixed.h>
#include <ap_int.h>


typedef ap_uint<8> pixel_type;
typedef ap_int<8> pixel_type_s;
typedef ap_ufixed<8,0, AP_RND, AP_SAT> comp_type;
typedef ap_fixed<10,2, AP_RND, AP_SAT> coeff_type;
struct video_stream {
	struct {
		pixel_type_s p1;
		pixel_type_s p2;
		pixel_type_s p3;
	} data;
	ap_uint<1> user;
	ap_uint<1> last;
};

struct coeffs {
	coeff_type c1;
	coeff_type c2;
	coeff_type c3;
};


void color_convert(video_stream* in_data, video_stream* out_data, coeffs c1, coeffs c2, coeffs c3, coeffs bias) {
#pragma HLS CLOCK domain=default
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE s_axilite register port=c1 clock=control
#pragma HLS INTERFACE s_axilite register port=c2 clock=control
#pragma HLS INTERFACE s_axilite register port=c3 clock=control
#pragma HLS INTERFACE s_axilite register port=bias clock=control
#pragma HLS INTERFACE axis port=in_data
#pragma HLS INTERFACE axis port=out_data

#pragma HLS pipeline II=1

	out_data->user = in_data->user;
	out_data->last = in_data->last;
	comp_type in1, in2, in3, out1, out2, out3;
	in1.range() = in_data->data.p1;
	in2.range() = in_data->data.p2;
	in3.range() = in_data->data.p3;

	out1 = in1 * c1.c1 + in2 * c1.c2 + in3 * c1.c3 + bias.c1;
	out2 = in1 * c2.c1 + in2 * c2.c2 + in3 * c2.c3 + bias.c2;
	out3 = in1 * c3.c1 + in2 * c3.c2 + in3 * c3.c3 + bias.c3;

	out_data->data.p1 = out1.range();
	out_data->data.p2 = out2.range();
	out_data->data.p3 = out3.range();
}

