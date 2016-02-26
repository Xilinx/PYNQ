//------------------------------------------------------------------------
//--
//--  Filename      : xlslice.v
//--
//--  Date          : 06/05/12
//-
//-  Description   : Verilog description of a slice block.  This
//-                  block does not use a core.
//-
//-----------------------------------------------------------------------

module  xlslice (Din,Dout);

	parameter DIN_WIDTH  = 32;
	parameter DIN_FROM = 8;
	parameter DIN_TO = 8;
	
	input [DIN_WIDTH -1:0] Din;
	output [DIN_FROM - DIN_TO:0] Dout;
	 
	assign Dout = Din [DIN_FROM: DIN_TO];
endmodule
