//------------------------------------------------------------------------
//--
//--  Filename      : xlconcat.v
//--
//--  Date          : 06/05/12
//-
//-  Description   : Verilog description of a concat block.  This
//-                  block does not use a core.
//-
//-----------------------------------------------------------------------

`timescale 1ps/1ps

module xlconcat (In0, In1, In2, In3, In4, In5, In6, In7, In8, In9, In10, In11, In12, In13, In14, In15, In16, In17, In18, In19, In20, In21, In22, In23, In24, In25, In26, In27, In28, In29, In30, In31, dout);
parameter IN0_WIDTH = 1;
input 	[IN0_WIDTH -1:0] In0;
parameter IN1_WIDTH = 1;
input 	[IN1_WIDTH -1:0] In1;
parameter IN2_WIDTH = 1;
input 	[IN2_WIDTH -1:0] In2;
parameter IN3_WIDTH = 1;
input 	[IN3_WIDTH -1:0] In3;
parameter IN4_WIDTH = 1;
input 	[IN4_WIDTH -1:0] In4;
parameter IN5_WIDTH = 1;
input 	[IN5_WIDTH -1:0] In5;
parameter IN6_WIDTH = 1;
input 	[IN6_WIDTH -1:0] In6;
parameter IN7_WIDTH = 1;
input 	[IN7_WIDTH -1:0] In7;
parameter IN8_WIDTH = 1;
input 	[IN8_WIDTH -1:0] In8;
parameter IN9_WIDTH = 1;
input 	[IN9_WIDTH -1:0] In9;
parameter IN10_WIDTH = 1;
input 	[IN10_WIDTH -1:0] In10;
parameter IN11_WIDTH = 1;
input 	[IN11_WIDTH -1:0] In11;
parameter IN12_WIDTH = 1;
input 	[IN12_WIDTH -1:0] In12;
parameter IN13_WIDTH = 1;
input 	[IN13_WIDTH -1:0] In13;
parameter IN14_WIDTH = 1;
input 	[IN14_WIDTH -1:0] In14;
parameter IN15_WIDTH = 1;
input 	[IN15_WIDTH -1:0] In15;
parameter IN16_WIDTH = 1;
input 	[IN16_WIDTH -1:0] In16;
parameter IN17_WIDTH = 1;
input 	[IN17_WIDTH -1:0] In17;
parameter IN18_WIDTH = 1;
input 	[IN18_WIDTH -1:0] In18;
parameter IN19_WIDTH = 1;
input 	[IN19_WIDTH -1:0] In19;
parameter IN20_WIDTH = 1;
input 	[IN20_WIDTH -1:0] In20;
parameter IN21_WIDTH = 1;
input 	[IN21_WIDTH -1:0] In21;
parameter IN22_WIDTH = 1;
input 	[IN22_WIDTH -1:0] In22;
parameter IN23_WIDTH = 1;
input 	[IN23_WIDTH -1:0] In23;
parameter IN24_WIDTH = 1;
input 	[IN24_WIDTH -1:0] In24;
parameter IN25_WIDTH = 1;
input 	[IN25_WIDTH -1:0] In25;
parameter IN26_WIDTH = 1;
input 	[IN26_WIDTH -1:0] In26;
parameter IN27_WIDTH = 1;
input 	[IN27_WIDTH -1:0] In27;
parameter IN28_WIDTH = 1;
input 	[IN28_WIDTH -1:0] In28;
parameter IN29_WIDTH = 1;
input 	[IN29_WIDTH -1:0] In29;
parameter IN30_WIDTH = 1;
input 	[IN30_WIDTH -1:0] In30;
parameter IN31_WIDTH = 1;
input 	[IN31_WIDTH -1:0] In31;
parameter dout_width = 2;
output [dout_width-1:0] dout;
parameter NUM_PORTS =2;


generate if (NUM_PORTS == 1)
begin : C_NUM_1
    assign dout = In0; 	
end
endgenerate

generate if (NUM_PORTS == 2)
begin : C_NUM_2
    assign dout = {In1,In0}; 	
end
endgenerate

generate if (NUM_PORTS == 3)
begin:C_NUM_3
	assign dout = {In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 4)
begin:C_NUM_4
    assign dout = {In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 5)
begin:C_NUM_5
    assign dout = {In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 6)
begin:C_NUM_6
    assign dout = {In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 7)
begin:C_NUM_7
    assign dout = {In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 8)
begin:C_NUM_8
    assign dout = {In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 9)
begin:C_NUM_9
    assign dout = {In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 10)
begin:C_NUM_10
    assign dout = {In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 11)
begin:C_NUM_11
    assign dout = {In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 12)
begin:C_NUM_12
    assign dout = {In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 13)
begin:C_NUM_13
    assign dout = {In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 14)
begin:C_NUM_14
    assign dout = {In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 15)
begin:C_NUM_15
    assign dout = {In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 16)
begin:C_NUM_16
    assign dout = {In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 17)
begin:C_NUM_17
    assign dout = {In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 18)
begin:C_NUM_18
    assign dout = {In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 19)
begin:C_NUM_19
    assign dout = {In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 20)
begin:C_NUM_20
    assign dout = {In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 21)
begin:C_NUM_21
    assign dout = {In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 22)
begin:C_NUM_22
    assign dout = {In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 23)
begin:C_NUM_23
    assign dout = {In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 24)
begin:C_NUM_24
    assign dout = {In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 25)
begin:C_NUM_25
    assign dout = {In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 26)
begin:C_NUM_26
    assign dout = {In25, In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 27)
begin:C_NUM_27
    assign dout = {In26, In25, In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 28)
begin:C_NUM_28
    assign dout = {In27, In26, In25, In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 29)
begin:C_NUM_29
    assign dout = {In28, In27, In26, In25, In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 30)
begin:C_NUM_30
    assign dout = {In29, In28, In27, In26, In25, In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 31)
begin:C_NUM_31
    assign dout = {In30, In29, In28, In27, In26, In25, In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

generate if (NUM_PORTS == 32)
begin:C_NUM_32
    assign dout = {In31, In30, In29, In28, In27, In26, In25, In24, In23, In22, In21, In20, In19, In18, In17, In16, In15, In14, In13, In12, In11, In10, In9, In8, In7, In6, In5, In4, In3, In2, In1, In0}; 	
end
endgenerate

endmodule
