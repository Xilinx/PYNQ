`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc
// Engineer: Parimal Patel
// Modified Date: 08/18/2017 to support PYNQ-Z2 board's Raspberry Pi and
//					and Arduino interfaces
//					C_INTERFACE=0 => ARDUINO, C_INTERFACE=1 => RASPBERRYPI
// Module Name: output_demux
//////////////////////////////////////////////////////////////////////////////////

module output_demux #(parameter C_FSM_SWITCH_WIDTH=20, C_INTERFACE=0)(
    input [4:0] sel,
    input in_pin,
    output reg [C_FSM_SWITCH_WIDTH-1:0] out_pin
    );
    
    generate
    case (C_INTERFACE)
       0: begin: ARDUINO
                 always @(sel, in_pin)
                   begin
                       out_pin = 20'h00000;
                       case(sel)
                           5'h00 : out_pin[0] = in_pin;
                           5'h01 : out_pin[1] = in_pin;
                           5'h02 : out_pin[2] = in_pin;
                           5'h03 : out_pin[3] = in_pin;
                           5'h04 : out_pin[4] = in_pin;
                           5'h05 : out_pin[5] = in_pin;
                           5'h06 : out_pin[6] = in_pin;
                           5'h07 : out_pin[7] = in_pin;
                           5'h08 : out_pin[8] = in_pin;
                           5'h09 : out_pin[9] = in_pin;
                           5'h0A : out_pin[10] = in_pin;
                           5'h0B : out_pin[11] = in_pin;
                           5'h0C : out_pin[12] = in_pin;
                           5'h0D : out_pin[13] = in_pin;
                           5'h0E : out_pin[14] = in_pin;
                           5'h0F : out_pin[15] = in_pin;
                           5'h10 : out_pin[16] = in_pin;
                           5'h11 : out_pin[17] = in_pin;
                           5'h12 : out_pin[18] = in_pin;
                           5'h13 : out_pin[19] = in_pin;
                       endcase
                   end
                 end
       1: begin: RASPBERRYPI
                 always @(sel, in_pin)
                   begin
                       out_pin = 26'h00000;
                       case(sel)
                           5'h00 : out_pin[0] = in_pin;
                           5'h01 : out_pin[1] = in_pin;
                           5'h02 : out_pin[2] = in_pin;
                           5'h03 : out_pin[3] = in_pin;
                           5'h04 : out_pin[4] = in_pin;
                           5'h05 : out_pin[5] = in_pin;
                           5'h06 : out_pin[6] = in_pin;
                           5'h07 : out_pin[7] = in_pin;
                           5'h08 : out_pin[8] = in_pin;
                           5'h09 : out_pin[9] = in_pin;
                           5'h0A : out_pin[10] = in_pin;
                           5'h0B : out_pin[11] = in_pin;
                           5'h0C : out_pin[12] = in_pin;
                           5'h0D : out_pin[13] = in_pin;
                           5'h0E : out_pin[14] = in_pin;
                           5'h0F : out_pin[15] = in_pin;
                           5'h10 : out_pin[16] = in_pin;
                           5'h11 : out_pin[17] = in_pin;
                           5'h12 : out_pin[18] = in_pin;
                           5'h13 : out_pin[19] = in_pin;
                           5'h14 : out_pin[20] = in_pin;
                           5'h15 : out_pin[21] = in_pin;
                           5'h16 : out_pin[22] = in_pin;
                           5'h17 : out_pin[23] = in_pin;
                           5'h18 : out_pin[24] = in_pin;
                           5'h19 : out_pin[25] = in_pin;
                       endcase
                   end
                  end
       default: begin: ARDUINO
                       always @(sel, in_pin)
                       begin
                           out_pin = 20'h00000;
                           case(sel)
                               5'h00 : out_pin[0] = in_pin;
                               5'h01 : out_pin[1] = in_pin;
                               5'h02 : out_pin[2] = in_pin;
                               5'h03 : out_pin[3] = in_pin;
                               5'h04 : out_pin[4] = in_pin;
                               5'h05 : out_pin[5] = in_pin;
                               5'h06 : out_pin[6] = in_pin;
                               5'h07 : out_pin[7] = in_pin;
                               5'h08 : out_pin[8] = in_pin;
                               5'h09 : out_pin[9] = in_pin;
                               5'h0A : out_pin[10] = in_pin;
                               5'h0B : out_pin[11] = in_pin;
                               5'h0C : out_pin[12] = in_pin;
                               5'h0D : out_pin[13] = in_pin;
                               5'h0E : out_pin[14] = in_pin;
                               5'h0F : out_pin[15] = in_pin;
                               5'h10 : out_pin[16] = in_pin;
                               5'h11 : out_pin[17] = in_pin;
                               5'h12 : out_pin[18] = in_pin;
                               5'h13 : out_pin[19] = in_pin;
                           endcase
                       end
                end
    endcase
    endgenerate


endmodule
