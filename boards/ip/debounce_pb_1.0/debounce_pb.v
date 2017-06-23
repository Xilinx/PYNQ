`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Design: Push button debounce
// Description: Debounces 20 ms Push buttons 
// Input: Expects 100 MHz clock
//////////////////////////////////////////////////////////////////////////////////
module  debounce_pb 
	(
	input clk, reset_n, button_in,				// inputs
	output reg 	DB_PB_out						// output
	);

	parameter N = 22 ;		// (2^ (23-1) )/ 100 MHz = 20 ms debounce time
// internal variables 
	reg  [N-1 : 0]	reg_q;						// timing regs
	reg  [N-1 : 0]	next_q;
	reg DFF1, DFF2;								// input flip-flops
	wire add_q;									// control flags
	wire reset_q;

	assign reset_q = (DFF1  ^ DFF2);		    // xor input flip flops to look for level chage to reset counter
	assign  add_q = ~(reg_q[N-1]);			    // add to counter when reg_q msb is equal to 0
	
//// combo counter to manage next_q	
	always @ ( reset_q, add_q, reg_q)
		begin
			case( {reset_q , add_q})
				2'b00 :
						next_q <= reg_q;
				2'b01 :
						next_q <= reg_q + 1;
				default :
						next_q <= { N {1'b0} };
			endcase 	
		end
	
//// Flip flop inputs and reg_q update
	always @ ( posedge clk )
		begin
			if(reset_n ==  1'b0)
				begin
					DFF1 <= 1'b0;
					DFF2 <= 1'b0;
					reg_q <= { N {1'b0} };
				end
			else
				begin
					DFF1 <= button_in;
					DFF2 <= DFF1;
					reg_q <= next_q;
				end
		end
	
//// counter control
	always @ ( posedge clk )
		begin
			if(reg_q[N-1] == 1'b1)
					DB_PB_out <= DFF2;
			else
					DB_PB_out <= DB_PB_out;
		end

endmodule


