#include <ap_int.h>
#include <cassert>
#include <iostream>

typedef ap_uint<8> pixel_type;
typedef ap_int<8> pixel_type_s;
typedef ap_fixed<10,2, AP_RND, AP_SAT> coeff_type;
struct video_stream {
	struct {
		pixel_type p1;
		pixel_type_s p2;
		pixel_type p3;
	} data;
	ap_uint<1> user;
	ap_uint<1> last;
};

struct coeffs {
	coeff_type c1;
	coeff_type c2;
	coeff_type c3;
};


void color_convert(video_stream* in_data, video_stream* out_data, coeffs c1, coeffs c2, coeffs c3, coeffs bias);

int main() {
	video_stream in, out;
	in.data.p1 = 64;
	in.data.p2 = 128;
	in.data.p3 = 191;
	in.user = 1;
	in.last = 0;

	coeffs c1,c2,c3,bias;

	c1.c1 = 1;
	c1.c2 = 1;
	c1.c3 = 1;
	c2.c1 = 0.5;
	c2.c2 = 0.5;
	c2.c3 = 0;
	c3.c1 = 0;
	c3.c2 = 0;
	c3.c3 = 1;

	bias.c1 = 0;
	bias.c2 = 0;
	bias.c3 = 0;


	color_convert(&in, &out, c1, c2, c3, bias);
	std::cout << out.data.p1  << " " << out.data.p2 << " " << out.data.p3 << std::endl;
	assert(out.data.p1 == 255);
	assert(out.data.p2 == 96);
	assert(out.data.p3 == 191);

}
