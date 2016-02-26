//
// Module: 	DRAM32XN
//
// Description: Distributed SelectRAM example
//		32 x 1 positive edge write, asynchronous read dual-port distributed RAM (Mapped to a SliceM LUT6)
//
// Device: 	Artix-7
//---------------------------------------------------------------------------------------

module DRAM32XN #(parameter data_width = 20)
                 (
                  DATA_IN,
                  ADDRESS,
                  ADDRESS_DP,
                  WRITE_EN,
                  CLK,
                  O_DATA_OUT,
                  O_DATA_OUT_DP);

input [data_width-1:0]DATA_IN;
input [3:0] ADDRESS;
input [3:0] ADDRESS_DP;
input WRITE_EN;
input CLK;

output [data_width-1:0]O_DATA_OUT_DP;
output [data_width-1:0]O_DATA_OUT;

genvar i;
generate
  for(i = 0 ; i < data_width; i = i + 1) begin : dram16s
    RAM32X1D #(
      .INIT(32'h00000000)     // Initial contents of RAM
   ) RAM32X1D_inst (
      .D(DATA_IN[i]),         // Write 1-bit data input
      .WE(WRITE_EN),          // Write enable input
      .WCLK(CLK),             // Write clock input
      .A0(ADDRESS[0]),        // Rw/ address[0] input bit
      .A1(ADDRESS[1]),        // Rw/ address[1] input bit
      .A2(ADDRESS[2]),        // Rw/ address[2] input bit
      .A3(ADDRESS[3]),        // Rw/ address[3] input bit
      .A4(1'b0),              // Rw/ address[4] input bit
      .DPRA0(ADDRESS_DP[0]),  // Read-only address[0] input bit
      .DPRA1(ADDRESS_DP[1]),  // Read-only address[1] input bit
      .DPRA2(ADDRESS_DP[2]),  // Read-only address[2] input bit
      .DPRA3(ADDRESS_DP[3]),  // Read-only address[3] input bit
      .DPRA4(1'b0),           // Read-only address[4] input bit
      .SPO(O_DATA_OUT[i]),    // Rw/ 1-bit data output
      .DPO(O_DATA_OUT_DP[i])  // Read-only 1-bit data output
   );
  end
endgenerate

endmodule

