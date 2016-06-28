
#include "ap_axi_sdata.h"

#pragma SDS data copy (A[0:length])
#pragma SDS data copy (B[0:length])
#pragma SDS data access_pattern(A:SEQUENTIAL, B:SEQUENTIAL)
void trace_controller(ap_axis<32,2,5,1> * A, ap_axis<32,2,5,1> * B,int length, int sample_rate);
void trace_controller(ap_axis<32,2,5,1> * A, ap_axis<32,2,5,1> * B,int length, int sample_rate){
#pragma HLS INTERFACE axis port=A
#pragma HLS INTERFACE axis port=B

 int i;
 int j;
 int sample_counter=1;
 int total_input_samples= length * sample_rate;

  for(i = 0; i < total_input_samples; i++){
	B[i].data = A[i].data;
	B[i].keep = 0xf;
    B[i].strb = 0xff;
    B[i].user = 0;
    B[i].last = (i == total_input_samples-1);
    B[i].id = 0;
    B[i].dest = (sample_counter != sample_rate); // 0: take the sample, 1: drop

    if(sample_counter == sample_rate){
    	sample_counter=1;
    } else {
    	sample_counter++;
    }




  }

}
