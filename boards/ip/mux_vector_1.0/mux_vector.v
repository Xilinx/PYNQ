`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////
// Module Name: mux_vector
/////////////////////////////////////////////////////////////////
module mux_vector #(parameter C_SIZE = 4 , DELAY = 3, C_NUM_CHANNELS=2)(
   input wire [C_SIZE-1:0] a,
   input wire [C_SIZE-1:0] b,
   input wire [C_SIZE-1:0] c,
   input wire [C_SIZE-1:0] d,
   input wire [C_SIZE-1:0] e,
   input wire [C_SIZE-1:0] f,
   input wire [C_SIZE-1:0] g,
   input wire [C_SIZE-1:0] h,
   input wire [2:0] sel,
   output wire [C_SIZE-1:0] y
   );
   
    reg [C_SIZE-1:0] data;

	always @(*) begin
		case(C_NUM_CHANNELS)
			2:	begin			
					case(sel)
						1'b0 : data[C_SIZE-1:0] <= a[C_SIZE-1:0] ;
						1'b1 : data[C_SIZE-1:0] <= b[C_SIZE-1:0] ;
						default : data[C_SIZE-1:0] <= a[C_SIZE-1:0] ;
					endcase
				end
			4:	begin			
					case(sel)
						2'b00 : data[C_SIZE-1:0] <= a[C_SIZE-1:0] ;
						2'b01 : data[C_SIZE-1:0] <= b[C_SIZE-1:0] ;
						2'b10 : data[C_SIZE-1:0] <= c[C_SIZE-1:0] ;
						2'b11 : data[C_SIZE-1:0] <= d[C_SIZE-1:0] ;
						default : data[C_SIZE-1:0] <= a[C_SIZE-1:0] ;
					endcase
				end
			8:	begin			
					case(sel)
						3'b000 : data[C_SIZE-1:0] <= a[C_SIZE-1:0] ;
						3'b001 : data[C_SIZE-1:0] <= b[C_SIZE-1:0] ;
						3'b010 : data[C_SIZE-1:0] <= c[C_SIZE-1:0] ;
						3'b011 : data[C_SIZE-1:0] <= d[C_SIZE-1:0] ;
						3'b100 : data[C_SIZE-1:0] <= e[C_SIZE-1:0] ;
						3'b101 : data[C_SIZE-1:0] <= f[C_SIZE-1:0] ;
						3'b110 : data[C_SIZE-1:0] <= g[C_SIZE-1:0] ;
						3'b111 : data[C_SIZE-1:0] <= h[C_SIZE-1:0] ;
						default : data[C_SIZE-1:0] <= a[C_SIZE-1:0] ;
					endcase
				end
		endcase
	end
	
    assign #DELAY y[C_SIZE-1:0] = data[C_SIZE-1:0] ;
	
endmodule
