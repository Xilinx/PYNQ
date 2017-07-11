#include "ap_axi_sdata.h"

/// frame based design
void trace_cntrl(ap_axis<64,2,5,1> * A, ap_axis<64,2,5,1> * B, ap_int<64> data_compare, int length) {
#pragma HLS INTERFACE axis depth=50 port=A
#pragma HLS INTERFACE axis depth=50 port=B
#pragma HLS INTERFACE s_axilite port=data_compare bundle=trace_cntrl
#pragma HLS INTERFACE s_axilite port=length bundle=trace_cntrl
#pragma HLS INTERFACE s_axilite port=return bundle=trace_cntrl
int match=0;
int i;
int samples=0;
ap_axis<64,2,5,1> A_temp;

	match = false;
	for ( i = 0 ; i<length ;) {
	#pragma HLS pipeline // goal II=1
		A_temp = *A++ ;
		match = match || ((data_compare.to_int() & (A_temp.data).to_int()) == data_compare.to_int());

		if (match==true)  {
		  A_temp.last=(samples==length-1);
		  *B++ = A_temp;
		  samples++;
		  i++;
		}
	}
}
