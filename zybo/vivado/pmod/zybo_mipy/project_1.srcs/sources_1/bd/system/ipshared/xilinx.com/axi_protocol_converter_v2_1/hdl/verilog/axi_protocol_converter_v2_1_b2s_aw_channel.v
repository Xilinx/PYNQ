`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_b2s_aw_channel #
(
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
                    // Width of ID signals.
                    // Range: >= 1.
  parameter integer C_ID_WIDTH          = 4,
                    // Width of AxADDR
                    // Range: 32.
  parameter integer C_AXI_ADDR_WIDTH    = 32

)
(
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  // AXI Slave Interface
  // Slave Interface System Signals
  input  wire                                 clk             ,
  input  wire                                 reset           ,

  // Slave Interface Write Address Ports
  input  wire [C_ID_WIDTH-1:0]                s_awid            ,
  input  wire [C_AXI_ADDR_WIDTH-1:0]          s_awaddr          ,
  input  wire [7:0]                           s_awlen           ,
  input  wire [2:0]                           s_awsize          ,
  input  wire [1:0]                           s_awburst         ,
  input  wire                                 s_awvalid         ,
  output wire                                 s_awready         ,

  output wire                                 m_awvalid         ,
  output wire [C_AXI_ADDR_WIDTH-1:0]          m_awaddr          ,
  input  wire                                 m_awready         ,

  // Connections to/from axi_protocol_converter_v2_1_6_b2s_b_channel module
  output wire                                 b_push           ,
  output wire [C_ID_WIDTH-1:0]                b_awid           ,
  output wire [7:0]                           b_awlen          ,
  input  wire                                 b_full

);

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////

wire                        next         ;
wire                        next_pending ;
wire                        a_push;
wire                        incr_burst;
reg  [C_ID_WIDTH-1:0]       s_awid_r;
reg  [7:0]                  s_awlen_r;

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////

// Translate the AXI transaction to the MC transaction(s)
axi_protocol_converter_v2_1_6_b2s_cmd_translator #
(
  .C_AXI_ADDR_WIDTH ( C_AXI_ADDR_WIDTH )
)
cmd_translator_0
(
  .clk           ( clk                   ) ,
  .reset         ( reset                 ) ,
  .s_axaddr      ( s_awaddr              ) ,
  .s_axlen       ( s_awlen               ) ,
  .s_axsize      ( s_awsize              ) ,
  .s_axburst     ( s_awburst             ) ,
  .s_axhandshake ( s_awvalid & a_push    ) ,
  .m_axaddr      ( m_awaddr              ) ,
  .incr_burst    ( incr_burst            ) ,
  .next          ( next                  ) ,
  .next_pending  ( next_pending          )
);


axi_protocol_converter_v2_1_6_b2s_wr_cmd_fsm aw_cmd_fsm_0
(
  .clk          ( clk            ) ,
  .reset        ( reset          ) ,
  .s_awready    ( s_awready      ) ,
  .s_awvalid    ( s_awvalid      ) ,
  .m_awvalid    ( m_awvalid      ) ,
  .m_awready    ( m_awready      ) ,
  .next         ( next           ) ,
  .next_pending ( next_pending   ) ,
  .b_push       ( b_push         ) ,
  .b_full       ( b_full         ) ,
  .a_push       ( a_push         )
);

assign b_awid = s_awid_r;
assign b_awlen = s_awlen_r;

always @(posedge clk) begin
  s_awid_r <= s_awid ;
  s_awlen_r <= s_awlen ;
end

endmodule

`default_nettype wire
