`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: boolean_fsm
// Project Name: PYNQ_Interface
// Target Devices: Z7020
// Description: This FSM module takes the one-clock wide start input and generates
//				chip enable (ce), configuration data in(cdi), and done signals.
//				The ce signal is valide for 32 clocks to shift 32-bit configuration
//				data for CFGLUT5. The cdi output is the next configuration bit that 
//				is shifted in to CFGLUT5. The done signal indicated when 32-bit
// 				configuration data are shifted in.
// 
//////////////////////////////////////////////////////////////////////////////////

module boolean_fsm(
    input clk,
    input start,
    input [(2**COUNTER_WIDTH)-1:0] fn_init_value,
    output reg cdi,
    output reg ce,
    output reg done
    );
    
    parameter COUNTER_WIDTH = 5;
    
    reg [(2**COUNTER_WIDTH)-1:0] fn_init_value_i;
    reg [COUNTER_WIDTH-1:0] cnt = {COUNTER_WIDTH{1'b0}};
    
    wire done_i;
    
    assign done_i = (cnt == (2**COUNTER_WIDTH-1)) ? 1'b1 : 1'b0;
    
    always @(posedge clk)
        done <= done_i;
    
    always @(posedge clk)
    begin
        if(start)
        begin
            ce <= 1'b1;
            cdi <= 1'b0;
            fn_init_value_i <= fn_init_value;
        end
        else if (done)
        begin
            ce <= 1'b0;
            cdi <= 1'b0;
            fn_init_value_i <= 32'b0;
        end
        else
        begin
            ce <= ce;
            cdi <= fn_init_value_i[31];
            fn_init_value_i = {fn_init_value_i[30:0], 1'b0};
        end
    end

   always @(posedge clk)
      if (!ce)
         cnt <= {COUNTER_WIDTH{1'b0}};
      else if (ce)
         cnt <= cnt + 1'b1;
    
endmodule
